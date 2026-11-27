import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/assessment_rubric.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import 'widgets/admin_scaffold.dart';

/// CRUD rubrik penilaian (deskripsi + rentang nilai per kategori/predikat).
class AdminRubricsScreen extends StatefulWidget {
  const AdminRubricsScreen({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminRubricsScreen> createState() => _AdminRubricsScreenState();
}

class _AdminRubricsScreenState extends State<AdminRubricsScreen> {
  late final AdminRepository _repository;
  List<AssessmentRubric> _rubrics = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAdminRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rubrics = await _repository.fetchRubrics();
      if (mounted) {
        setState(() => _rubrics = rubrics);
      }
    } on AdminRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditor([AssessmentRubric? rubric]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _RubricDialog(repository: _repository, rubric: rubric),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grouped = <AssessmentCategory, List<AssessmentRubric>>{};
    for (final rubric in _rubrics) {
      grouped.putIfAbsent(rubric.category, () => []).add(rubric);
    }

    final children = <Widget>[];
    for (final category in AssessmentCategory.values) {
      final rubrics = grouped[category];
      if (rubrics == null || rubrics.isEmpty) {
        continue;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(
            category.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      for (final rubric in rubrics) {
        children.add(
          Card(
            child: ListTile(
              onTap: () => _openEditor(rubric),
              isThreeLine: rubric.description.length > 48,
              leading: Icon(
                _predicateIcon(rubric.predicate),
                color: rubric.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      rubric.predicate.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rubric.scoreRangeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  rubric.isActive
                      ? rubric.description
                      : '${rubric.description} (nonaktif)',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        );
        children.add(const SizedBox(height: 10));
      }
    }

    return AdminListScaffold(
      title: 'Rubrik Penilaian',
      subtitle:
          'Rubrik tampil sebagai panduan pada form penilaian. Satu rubrik per '
          'kombinasi kategori dan predikat; perubahan teks tidak mengubah data '
          'penilaian lama.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage:
          'Belum ada rubrik. Tambahkan rubrik agar penilai melihat panduan '
          'predikat pada form.',
      onAdd: () => _openEditor(),
      addTooltip: 'Tambah rubrik',
      children: children,
    );
  }

  IconData _predicateIcon(Predicate predicate) {
    return switch (predicate) {
      Predicate.mumtaz => Icons.workspace_premium_rounded,
      Predicate.jayyidJiddan => Icons.thumb_up_alt_outlined,
      Predicate.jayyid => Icons.check_circle_outline_rounded,
      Predicate.mengulang => Icons.replay_rounded,
    };
  }
}

class _RubricDialog extends StatefulWidget {
  const _RubricDialog({required this.repository, this.rubric});

  final AdminRepository repository;
  final AssessmentRubric? rubric;

  @override
  State<_RubricDialog> createState() => _RubricDialogState();
}

class _RubricDialogState extends State<_RubricDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late AssessmentCategory _category;
  late Predicate _predicate;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.rubric != null;

  @override
  void initState() {
    super.initState();
    final rubric = widget.rubric;
    _descriptionController = TextEditingController(
      text: rubric?.description ?? '',
    );
    _minController = TextEditingController(
      text: rubric?.minScore == null ? '' : _formatScore(rubric!.minScore!),
    );
    _maxController = TextEditingController(
      text: rubric?.maxScore == null ? '' : _formatScore(rubric!.maxScore!),
    );
    _category = rubric?.category ?? AssessmentCategory.ziyadah;
    _predicate = rubric?.predicate ?? Predicate.mumtaz;
    _isActive = rubric?.isActive ?? true;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _formatScore(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  double? _parseScore(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final minScore = _parseScore(_minController.text);
    final maxScore = _parseScore(_maxController.text);
    if (minScore != null && maxScore != null && minScore > maxScore) {
      setState(() => _errorMessage = 'Nilai minimum tidak boleh lebih besar.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.saveRubric(
        id: widget.rubric?.id,
        category: _category,
        predicate: _predicate,
        description: _descriptionController.text,
        minScore: minScore,
        maxScore: maxScore,
        isActive: _isActive,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AdminRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Rubrik?'),
        content: const Text(
          'Rubrik ini akan dihapus dari panduan form. Data penilaian yang '
          'sudah ada tidak terpengaruh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.repository.deleteRubric(widget.rubric!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AdminRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Ubah Rubrik' : 'Tambah Rubrik'),
      content: SizedBox(
        width: 440,
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
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _predicate = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / kriteria',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Deskripsi rubrik wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nilai minimum',
                        ),
                        validator: (value) =>
                            _validateScore(value, 'Nilai minimum'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nilai maksimum',
                        ),
                        validator: (value) =>
                            _validateScore(value, 'Nilai maksimum'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rubrik aktif'),
                  subtitle: const Text(
                    'Rubrik nonaktif tidak tampil di form penilaian.',
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
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
        if (_isEditing)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
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
              : const Text('Simpan'),
        ),
      ],
    );
  }

  String? _validateScore(String? value, String field) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) {
      return '$field harus angka.';
    }
    if (parsed < 0 || parsed > 100) {
      return '$field harus 0–100.';
    }
    return null;
  }
}
