import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../assessment/domain/academic_period.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import 'widgets/admin_scaffold.dart';

class AdminPeriodsScreen extends StatefulWidget {
  const AdminPeriodsScreen({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminPeriodsScreen> createState() => _AdminPeriodsScreenState();
}

class _AdminPeriodsScreenState extends State<AdminPeriodsScreen> {
  late final AdminRepository _repository;
  List<AcademicPeriod> _periods = const [];
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
      final periods = await _repository.fetchPeriods();
      if (mounted) {
        setState(() => _periods = periods);
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

  Future<void> _openEditor([AcademicPeriod? period]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PeriodDialog(repository: _repository, period: period),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(AcademicPeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Periode?'),
        content: Text(
          'Periode "${period.name}" akan dihapus. Penilaian tidak terhapus, '
          'tetapi filter periode ini tidak tersedia lagi.',
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

    try {
      await _repository.deletePeriod(period.id);
      if (mounted) {
        showAdminMessage(context, 'Periode dihapus.');
        await _load();
      }
    } on AdminRepositoryException catch (error) {
      if (mounted) {
        showAdminMessage(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminListScaffold(
      title: 'Periode Akademik',
      subtitle:
          'Periode dipakai sebagai filter riwayat dan perbandingan grafik. '
          'Hanya satu periode boleh menjadi default.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage: 'Belum ada periode akademik.',
      onAdd: () => _openEditor(),
      addTooltip: 'Tambah periode',
      children: [
        for (final period in _periods) ...[
          Card(
            child: ListTile(
              onTap: () => _openEditor(period),
              leading: Icon(
                Icons.date_range_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                period.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${AppFormatters.shortDate(period.startDate)} – '
                '${AppFormatters.shortDate(period.endDate)} • '
                '${_typeLabel(period.periodType)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (period.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Default',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _delete(period),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Hapus periode',
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _typeLabel(String value) {
    return switch (value) {
      'bulanan' => 'Bulanan',
      'semester' => 'Semester',
      'tahunan' => 'Tahunan',
      _ => 'Custom',
    };
  }
}

class _PeriodDialog extends StatefulWidget {
  const _PeriodDialog({required this.repository, this.period});

  final AdminRepository repository;
  final AcademicPeriod? period;

  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _periodType;
  late bool _isDefault;
  bool _isSaving = false;
  String? _errorMessage;

  static const _types = ['bulanan', 'semester', 'tahunan', 'custom'];

  bool get _isEditing => widget.period != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameController = TextEditingController(text: widget.period?.name ?? '');
    _startDate = widget.period?.startDate ?? DateTime(now.year, 1, 1);
    _endDate = widget.period?.endDate ??
        DateTime(now.year, now.month, now.day);
    _periodType = widget.period?.periodType ?? 'semester';
    _isDefault = widget.period?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Tanggal mulai' : 'Tanggal selesai',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() => _errorMessage = 'Tanggal selesai harus setelah mulai.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await widget.repository.updatePeriod(
          id: widget.period!.id,
          name: _nameController.text,
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
          isDefault: _isDefault,
        );
      } else {
        await widget.repository.createPeriod(
          name: _nameController.text,
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
          isDefault: _isDefault,
        );
      }
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
      title: Text(_isEditing ? 'Ubah Periode' : 'Tambah Periode'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama periode',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                      ? 'Nama periode wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _periodType,
                  decoration: const InputDecoration(labelText: 'Jenis periode'),
                  items: [
                    for (final type in _types)
                      DropdownMenuItem(
                        value: type,
                        child: Text(switch (type) {
                          'bulanan' => 'Bulanan',
                          'semester' => 'Semester',
                          'tahunan' => 'Tahunan',
                          _ => 'Custom',
                        }),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _periodType = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Mulai',
                        date: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateField(
                        label: 'Selesai',
                        date: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Jadikan periode default'),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      height: 1.4,
                    ),
                  ),
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
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.event_outlined, size: 18),
        ),
        child: Text(AppFormatters.shortDate(date)),
      ),
    );
  }
}
