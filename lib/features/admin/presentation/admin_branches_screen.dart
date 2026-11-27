import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import 'widgets/admin_scaffold.dart';

class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  late final AdminRepository _repository;
  List<BranchInfo> _branches = const [];
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
      final branches = await _repository.fetchBranches();
      if (mounted) {
        setState(() => _branches = branches);
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

  Future<void> _openEditor([BranchInfo? branch]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _BranchDialog(repository: _repository, branch: branch),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminListScaffold(
      title: 'Cabang',
      subtitle:
          'Cabang nonaktif tetap tersimpan agar riwayat penilaian lama tetap '
          'utuh. Nama cabang harus unik.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage: 'Belum ada cabang. Tambahkan minimal satu cabang.',
      onAdd: () => _openEditor(),
      addTooltip: 'Tambah cabang',
      children: [
        for (final branch in _branches) ...[
          Card(
            child: ListTile(
              onTap: () => _openEditor(branch),
              leading: Icon(
                Icons.account_tree_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                branch.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(branch.isActive ? 'Aktif' : 'Nonaktif'),
              trailing: Icon(
                branch.isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: branch.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BranchDialog extends StatefulWidget {
  const _BranchDialog({required this.repository, this.branch});

  final AdminRepository repository;
  final BranchInfo? branch;

  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends State<_BranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _isActive = widget.branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await widget.repository.updateBranch(
          id: widget.branch!.id,
          name: _nameController.text,
          isActive: _isActive,
        );
      } else {
        await widget.repository.createBranch(_nameController.text);
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
      title: Text(_isEditing ? 'Ubah Cabang' : 'Tambah Cabang'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nama cabang'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                  ? 'Nama cabang wajib diisi.'
                  : null,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cabang aktif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
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
