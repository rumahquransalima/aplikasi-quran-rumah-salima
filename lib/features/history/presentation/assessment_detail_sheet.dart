import 'package:flutter/material.dart';

import '../../../core/constants/juz_options.dart';
import '../../../core/utils/formatters.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/audit_log_entry.dart';
import '../../assessment/presentation/widgets/predicate_badge.dart';
import '../../auth/domain/app_user.dart';

/// Menampilkan detail penilaian, aksi koreksi/hapus, dan audit log (admin).
///
/// Mengembalikan `true` jika data berubah sehingga daftar pemanggil perlu
/// dimuat ulang.
Future<bool?> showAssessmentDetailSheet(
  BuildContext context, {
  required AppUser user,
  required Assessment assessment,
  AssessmentRepository? repository,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AssessmentDetailSheet(
      user: user,
      assessment: assessment,
      repository: repository ?? SupabaseAssessmentRepository(),
    ),
  );
}

class _AssessmentDetailSheet extends StatefulWidget {
  const _AssessmentDetailSheet({
    required this.user,
    required this.assessment,
    required this.repository,
  });

  final AppUser user;
  final Assessment assessment;
  final AssessmentRepository repository;

  @override
  State<_AssessmentDetailSheet> createState() => _AssessmentDetailSheetState();
}

class _AssessmentDetailSheetState extends State<_AssessmentDetailSheet> {
  List<AuditLogEntry> _auditLogs = const [];
  bool _isLoadingLogs = false;
  String? _logsError;
  bool _isDeleting = false;

  bool get _canCorrect => widget.user.isAdmin || widget.user.isMusyrifah;

  bool get _canDelete => widget.user.isAdmin;

  @override
  void initState() {
    super.initState();
    if (widget.user.isAdmin) {
      _loadAuditLogs();
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoadingLogs = true;
      _logsError = null;
    });

    try {
      final logs = await widget.repository.fetchAuditLogs(
        assessmentId: widget.assessment.id,
        limit: 20,
      );
      if (mounted) {
        setState(() => _auditLogs = logs);
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _logsError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  Future<void> _openCorrection() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _CorrectionDialog(
        assessment: widget.assessment,
        repository: widget.repository,
      ),
    );

    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(
        title: 'Hapus Penilaian?',
        description:
            'Data penilaian akan dihapus permanen, tetapi jejaknya tetap '
            'tercatat di audit log bersama alasan penghapusan.',
        confirmLabel: 'Hapus',
        hintText: 'Alasan penghapusan (wajib)',
      ),
    );

    if (reason == null || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await widget.repository.deleteAssessment(
        assessmentId: widget.assessment.id,
        reason: reason,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assessment = widget.assessment;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.category.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppFormatters.longDate(assessment.assessmentDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PredicateBadge(predicate: assessment.predicate),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Mahasantri',
                    value: assessment.studentNis == null
                        ? assessment.studentName
                        : '${assessment.studentName} • '
                              '${assessment.studentNis}',
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Cabang (snapshot)',
                    value: assessment.branchName,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Rentang Juz',
                    value: assessment.juzLabel,
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.speed_rounded,
                    label: 'Nilai numerik',
                    value: AppFormatters.score(assessment.numericScore),
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Penilai',
                    value: assessment.evaluatorName,
                  ),
                  if (assessment.notes != null &&
                      assessment.notes!.trim().isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assessment.category.usesEvaluationParagraph
                                ? 'Paragraf evaluasi'
                                : 'Catatan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            assessment.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (assessment.updatedAt != null &&
                assessment.updatedAt!.isAfter(assessment.createdAt)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Terakhir dikoreksi '
                      '${AppFormatters.shortDate(assessment.updatedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_canCorrect || _canDelete) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_canCorrect)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _openCorrection,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Koreksi'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  if (_canCorrect && _canDelete) const SizedBox(width: 10),
                  if (_canDelete)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _confirmDelete,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (widget.user.isAdmin) ...[
              const SizedBox(height: 24),
              Text(
                'Audit Log Koreksi',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hanya admin yang dapat melihat jejak perubahan.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoadingLogs)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_logsError != null)
                Text(
                  _logsError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                )
              else if (_auditLogs.isEmpty)
                Text(
                  'Belum ada koreksi pada penilaian ini.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final log in _auditLogs) ...[
                  _AuditLogTile(log: log),
                  if (log != _auditLogs.last) const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log});

  final AuditLogEntry log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.isDelete
                    ? Icons.delete_outline_rounded
                    : Icons.edit_outlined,
                size: 16,
                color: log.isDelete ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                log.isDelete ? 'Hapus' : 'Koreksi',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.shortDate(log.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Oleh ${log.changedByName ?? 'Pengguna'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (log.correctionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Alasan: ${log.correctionReason}',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
          if (!log.isDelete && log.oldData != null && log.newData != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _describeChanges(log.oldData!, log.newData!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _describeChanges(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    const labels = {
      'predicate': 'Predikat',
      'numeric_score': 'Nilai',
      'notes': 'Catatan',
      'juz_start': 'Juz dari',
      'juz_end': 'Juz sampai',
      'assessment_date': 'Tanggal',
      'category': 'Kategori',
    };

    final changes = <String>[];
    for (final entry in labels.entries) {
      final before = oldData[entry.key];
      final after = newData[entry.key];
      if (before != after) {
        changes.add(
          '${entry.value}: ${_displayValue(before)} → ${_displayValue(after)}',
        );
      }
    }

    return changes.isEmpty ? 'Tidak ada perubahan nilai.' : changes.join('\n');
  }

  String _displayValue(Object? value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return '(kosong)';
    }
    return '$value';
  }
}

class _CorrectionDialog extends StatefulWidget {
  const _CorrectionDialog({
    required this.assessment,
    required this.repository,
  });

  final Assessment assessment;
  final AssessmentRepository repository;

  @override
  State<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _scoreController = TextEditingController();
  final _notesController = TextEditingController();

  String? _juzStart;
  String? _juzEnd;
  Predicate? _predicate;
  late AssessmentCategory _category;
  late DateTime _assessmentDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final assessment = widget.assessment;
    _juzStart = assessment.juzStart;
    _juzEnd = assessment.juzEnd;
    _predicate = assessment.predicate;
    _category = assessment.category;
    _assessmentDate = assessment.assessmentDate;
    _scoreController.text = assessment.numericScore == null
        ? ''
        : AppFormatters.score(assessment.numericScore);
    _notesController.text = assessment.notes ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _scoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final scoreText = _scoreController.text.trim();
    final score = scoreText.isEmpty
        ? null
        : double.tryParse(scoreText.replaceAll(',', '.'));
    final notes = _notesController.text.trim();

    final changes = <String, dynamic>{};
    if (_category != widget.assessment.category) {
      changes['category'] = _category.value;
    }
    if (!_isSameDay(_assessmentDate, widget.assessment.assessmentDate)) {
      changes['assessment_date'] = AppFormatters.isoDate(_assessmentDate);
    }
    if (_predicate != widget.assessment.predicate) {
      changes['predicate'] = _predicate?.value;
    }
    if (score != widget.assessment.numericScore) {
      changes['numeric_score'] = score;
    }
    if (notes != (widget.assessment.notes ?? '')) {
      changes['notes'] = notes;
    }
    if (_juzStart != widget.assessment.juzStart) {
      changes['juz_start'] = _juzStart;
    }
    if (_juzEnd != widget.assessment.juzEnd) {
      changes['juz_end'] = _juzEnd;
    }

    if (changes.isEmpty) {
      setState(() => _errorMessage = 'Tidak ada perubahan untuk disimpan.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.correctAssessment(
        assessmentId: widget.assessment.id,
        reason: _reasonController.text.trim(),
        changes: changes,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Koreksi gagal disimpan.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Pilih tanggal penilaian',
    );

    if (picked != null && mounted) {
      setState(
        () => _assessmentDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Koreksi Penilaian'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<AssessmentCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    for (final category in AssessmentCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal penilaian',
                      prefixIcon: Icon(Icons.event_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                    ),
                    child: Text(
                      AppFormatters.longDate(_assessmentDate),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _juzStart,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Juz dari'),
                        items: [
                          for (final juz in JuzOptions.values)
                            DropdownMenuItem(value: juz, child: Text(juz)),
                        ],
                        onChanged: (value) =>
                            setState(() => _juzStart = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _juzEnd,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Juz sampai',
                        ),
                        items: [
                          for (final juz in JuzOptions.values)
                            DropdownMenuItem(value: juz, child: Text(juz)),
                        ],
                        onChanged: (value) =>
                            setState(() => _juzEnd = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Predicate>(
                  initialValue: _predicate,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Predikat'),
                  items: [
                    for (final predicate in Predicate.values)
                      DropdownMenuItem(
                        value: predicate,
                        child: Text(predicate.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _predicate = value),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nilai numerik',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0 || parsed > 100) {
                      return 'Nilai harus 0–100.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / paragraf evaluasi',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _reasonController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alasan koreksi (wajib)',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Alasan wajib diisi agar tercatat di audit log.'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan Koreksi'),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.hintText,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String hintText;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Alasan wajib diisi.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: widget.hintText,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
