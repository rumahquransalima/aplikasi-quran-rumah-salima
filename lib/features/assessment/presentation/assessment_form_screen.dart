import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/juz_options.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/domain/app_user.dart';
import '../data/assessment_repository.dart';
import '../data/supabase_assessment_repository.dart';
import '../domain/assessment.dart';
import '../domain/assessment_rubric.dart';
import '../domain/student_option.dart';

/// Form input penilaian untuk Ziyadah, Murojaah, Tahsin, Tashih, Tasmi', dan
/// Juziah.
///
/// Identitas penilai TIDAK diinput manual: `evaluator_id` diisi otomatis oleh
/// trigger database dari sesi login, dan `branch_id` dari cabang mahasantri.
class AssessmentFormScreen extends StatefulWidget {
  const AssessmentFormScreen({
    super.key,
    required this.user,
    required this.category,
    this.repository,
    this.initialStudentId,
  });

  final AppUser user;
  final AssessmentCategory category;
  final AssessmentRepository? repository;
  final String? initialStudentId;

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _notesController = TextEditingController();

  late final AssessmentRepository _repository;
  late DateTime _date;

  List<StudentOption> _students = const [];
  List<AssessmentRubric> _rubrics = const [];
  String? _studentId;
  String? _juzStart;
  String? _juzEnd;
  Predicate? _predicate;
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;
  String? _loadError;

  bool get _canInput => widget.user.isAdmin || widget.user.isMusyrifah;

  bool get _usesEvaluationParagraph => widget.category.usesEvaluationParagraph;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _studentId = widget.initialStudentId;
    if (_canInput) {
      _loadStudents();
      _loadRubrics();
    } else {
      _isLoadingStudents = false;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _loadError = null;
    });

    try {
      final students = await _repository.fetchStudents();
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students.where((student) => student.isActive).toList();
        if (_studentId != null &&
            !_students.any((student) => student.id == _studentId)) {
          _studentId = null;
        }
      });
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _loadError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _loadRubrics() async {
    try {
      final rubrics = await _repository.fetchActiveRubrics();
      if (mounted) {
        setState(() => _rubrics = rubrics);
      }
    } on AssessmentRepositoryException {
      // Rubrik hanya panduan; kegagalan memuatnya tidak menghalangi input.
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Pilih tanggal penilaian',
    );

    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_canInput) {
      _showMessage('Hanya admin dan musyrifah yang dapat menginput penilaian.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final notes = _notesController.text.trim();
    final scoreText = _scoreController.text.trim();

    try {
      await _repository.createAssessment(
        AssessmentDraft(
          studentId: _studentId!,
          category: widget.category,
          assessmentDate: _date,
          juzStart: _juzStart,
          juzEnd: _juzEnd,
          predicate: _predicate,
          numericScore: scoreText.isEmpty
              ? null
              : double.parse(scoreText.replaceAll(',', '.')),
          notes: notes.isEmpty ? null : notes,
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on AssessmentRepositoryException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Penilaian gagal disimpan. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Penilaian ${widget.category.label}')),
      body: SafeArea(
        child: !_canInput
            ? const _RestrictedNotice()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _CategoryBanner(category: widget.category),
                    const SizedBox(height: 16),
                    _EvaluatorCard(user: widget.user),
                    const SizedBox(height: 16),
                    if (_isLoadingStudents)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadError != null)
                      _LoadErrorCard(
                        message: _loadError!,
                        onRetry: _loadStudents,
                      )
                    else
                      ..._buildFormFields(context),
                    const SizedBox(height: 24),
                    if (!_isLoadingStudents && _loadError == null)
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSubmitting ? 'Menyimpan...' : 'Simpan Penilaian',
                        ),
                      ),
                    if (_students.isEmpty &&
                        !_isLoadingStudents &&
                        _loadError == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Belum ada mahasantri aktif yang dapat dinilai. '
                          'Hubungi admin untuk penugasan cabang atau '
                          'penambahan data mahasantri.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildFormFields(BuildContext context) {
    final theme = Theme.of(context);

    return [
      DropdownButtonFormField<String>(
        initialValue: _studentId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Mahasantri',
          hintText: 'Pilih mahasantri',
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
        items: [
          for (final student in _students)
            DropdownMenuItem(
              value: student.id,
              child: Text(
                '${student.displayLabel} • ${student.branchName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _students.isEmpty
            ? null
            : (value) => setState(() => _studentId = value),
        validator: (value) =>
            value == null ? 'Mahasantri wajib dipilih.' : null,
      ),
      const SizedBox(height: 14),
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Tanggal penilaian',
            prefixIcon: Icon(Icons.event_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
          ),
          child: Text(AppFormatters.longDate(_date)),
        ),
      ),
      const SizedBox(height: 14),
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
              onChanged: (value) => setState(() {
                _juzStart = value;
                if (_juzEnd != null && _juzEndIndex < _juzStartIndex) {
                  _juzEnd = value;
                }
              }),
              validator: (value) => value == null ? 'Wajib diisi.' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _juzEnd,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Juz sampai'),
              items: [
                for (final juz in JuzOptions.values)
                  DropdownMenuItem(value: juz, child: Text(juz)),
              ],
              onChanged: (value) => setState(() => _juzEnd = value),
              validator: (value) {
                if (value == null) {
                  return 'Wajib diisi.';
                }
                if (_juzStart != null && _juzEndIndex < _juzStartIndex) {
                  return 'Tidak boleh sebelum juz awal.';
                }
                return null;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<Predicate>(
        initialValue: _predicate,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.category.isPlaceholder
              ? 'Predikat (opsional)'
              : 'Predikat',
          hintText: 'Pilih predikat',
          prefixIcon: const Icon(Icons.military_tech_outlined),
        ),
        items: [
          for (final predicate in Predicate.values)
            DropdownMenuItem(value: predicate, child: Text(predicate.label)),
        ],
        onChanged: (value) => setState(() => _predicate = value),
        validator: (value) {
          if (_usesEvaluationParagraph || !widget.category.isPlaceholder) {
            return value == null ? 'Predikat wajib dipilih.' : null;
          }
          return null;
        },
      ),
      if (_selectedRubric != null) ...[
        const SizedBox(height: 10),
        _RubricGuide(rubric: _selectedRubric!),
      ],
      const SizedBox(height: 14),
      TextFormField(
        controller: _scoreController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Nilai numerik (opsional, 0–100)',
          prefixIcon: Icon(Icons.numbers_rounded),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) {
            return null;
          }
          final parsed = double.tryParse(text.replaceAll(',', '.'));
          if (parsed == null) {
            return 'Nilai harus berupa angka.';
          }
          if (parsed < 0 || parsed > 100) {
            return 'Nilai harus di antara 0 dan 100.';
          }
          return null;
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _notesController,
        minLines: _usesEvaluationParagraph ? 4 : 2,
        maxLines: _usesEvaluationParagraph ? 8 : 4,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          labelText: _usesEvaluationParagraph
              ? 'Paragraf evaluasi'
              : 'Catatan (opsional)',
          alignLabelWithHint: true,
          prefixIcon: _usesEvaluationParagraph
              ? null
              : const Icon(Icons.notes_rounded),
        ),
        validator: (value) {
          if (_usesEvaluationParagraph &&
              (value == null || value.trim().isEmpty)) {
            return 'Paragraf evaluasi wajib diisi.';
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      Text(
        'Penilai: ${widget.user.fullName} • ${widget.user.role.label}. '
        'Identitas ini dikunci oleh server dan tidak dapat diubah dari form.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      if (widget.category.isPlaceholder) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Detail kriteria penilaian ${widget.category.label} menyusul. '
            'Saat ini form menyimpan tanggal, rentang juz, predikat, nilai, '
            'dan catatan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              height: 1.4,
            ),
          ),
        ),
      ],
    ];
  }

  AssessmentRubric? get _selectedRubric => AssessmentRubric.findFor(
    _rubrics,
    category: widget.category,
    predicate: _predicate,
  );

  int get _juzStartIndex => JuzOptions.values.indexOf(_juzStart ?? '');

  int get _juzEndIndex => JuzOptions.values.indexOf(_juzEnd ?? '');
}

class _RubricGuide extends StatelessWidget {
  const _RubricGuide({required this.rubric});

  final AssessmentRubric rubric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule_outlined,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Rubrik ${rubric.predicate.label}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                rubric.scoreRangeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rubric.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category});

  final AssessmentCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  category.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluatorCard extends StatelessWidget {
  const _EvaluatorCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            user.initials,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text('${user.role.label} • ${user.branchLabel}'),
        trailing: const Icon(Icons.lock_outline_rounded, size: 18),
      ),
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: colorScheme.onErrorContainer,
              side: BorderSide(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictedNotice extends StatelessWidget {
  const _RestrictedNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Akses input penilaian dibatasi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hanya admin dan musyrifah yang dapat menginput penilaian. '
              'Mahasantri hanya dapat melihat data pribadi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
