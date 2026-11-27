import 'package:flutter/material.dart';

import '../../auth/domain/user_role.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_scaffold.dart';

/// Kelola role dan status aktif pengguna. Email & identitas auth tidak diubah.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    required this.currentUserId,
    this.repository,
  });

  final String currentUserId;
  final AdminRepository? repository;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final AdminRepository _repository;
  List<AdminProfile> _profiles = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';

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
      final profiles = await _repository.fetchProfiles();
      if (mounted) {
        setState(() => _profiles = profiles);
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

  List<AdminProfile> get _visible {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _profiles;
    }
    return _profiles
        .where(
          (profile) =>
              profile.fullName.toLowerCase().contains(query) ||
              (profile.email?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  Future<void> _openEditor(AdminProfile profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(
        repository: _repository,
        profile: profile,
        isSelf: profile.id == widget.currentUserId,
      ),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = _visible;

    return AdminListScaffold(
      title: 'Pengguna & Peran',
      subtitle:
          'Perubahan role dan status aktif langsung berlaku pada akun. Akun '
          'nonaktif akan ditahan di layar "Akun Belum Aktif".',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage: 'Belum ada pengguna terdaftar.',
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Cari nama atau email',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const AdminEmptyCard(message: 'Tidak ada pengguna yang cocok.')
        else
          for (final profile in visible) ...[
            Card(
              child: ListTile(
                onTap: () => _openEditor(profile),
                leading: CircleAvatar(
                  backgroundColor: profile.isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    profile.role == UserRole.admin
                        ? Icons.admin_panel_settings_outlined
                        : profile.role == UserRole.musyrifah
                        ? Icons.school_outlined
                        : Icons.person_outline_rounded,
                    size: 20,
                    color: profile.isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  profile.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  [
                    profile.email ?? 'Tanpa email',
                    profile.role.label,
                    if (!profile.isActive) 'Nonaktif',
                    if (profile.id == widget.currentUserId) 'Akun Anda',
                  ].join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({
    required this.repository,
    required this.profile,
    required this.isSelf,
  });

  final AdminRepository repository;
  final AdminProfile profile;
  final bool isSelf;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late UserRole _role;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _role = widget.profile.role;
    _isActive = widget.profile.isActive;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.updateUser(
        id: widget.profile.id,
        role: _role,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Ubah Pengguna'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.profile.email ?? widget.profile.fullName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Peran'),
            items: [
              for (final role in UserRole.values)
                DropdownMenuItem(value: role, child: Text(role.label)),
            ],
            onChanged: widget.isSelf
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _role = value);
                    }
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Akun aktif'),
            value: _isActive,
            onChanged: widget.isSelf
                ? null
                : (value) => setState(() => _isActive = value),
          ),
          if (widget.isSelf)
            Text(
              'Role dan status akun Anda sendiri tidak dapat diubah dari sini '
              'untuk mencegah kehilangan akses admin.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
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
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving || widget.isSelf ? null : _save,
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
