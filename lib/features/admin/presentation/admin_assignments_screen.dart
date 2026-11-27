import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_scaffold.dart';

class AdminAssignmentsScreen extends StatefulWidget {
  const AdminAssignmentsScreen({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  late final AdminRepository _repository;
  List<StaffAssignment> _assignments = const [];
  List<AdminProfile> _musyrifah = const [];
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
      final profiles = await _repository.fetchProfiles();
      final branches = await _repository.fetchBranches();
      final assignments = await _repository.fetchAssignments();
      if (mounted) {
        setState(() {
          _musyrifah = profiles
              .where(
                (profile) =>
                    profile.role == UserRole.musyrifah && profile.isActive,
              )
              .toList(growable: false);
          _branches = branches.where((branch) => branch.isActive).toList();
          _assignments = assignments;
        });
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

  Future<void> _openAdd() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AssignmentDialog(
        repository: _repository,
        musyrifah: _musyrifah,
        branches: _branches,
      ),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _remove(StaffAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Penugasan?'),
        content: Text(
          '${assignment.userName} tidak lagi dapat mengakses data '
          '${assignment.branchName}. Riwayat penilaian tetap tersimpan.',
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
      await _repository.removeAssignment(assignment.id);
      if (mounted) {
        showAdminMessage(context, 'Penugasan dihapus.');
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
      title: 'Penugasan Musyrifah',
      subtitle:
          'Satu musyrifah boleh ditugaskan di beberapa cabang. Akses data '
          'digabung oleh RLS sesuai daftar penugasan.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage:
          'Belum ada penugasan. Ubah role akun menjadi musyrifah terlebih '
          'dahulu, lalu tambahkan penugasan cabang.',
      onAdd: _musyrifah.isEmpty || _branches.isEmpty ? null : _openAdd,
      addTooltip: 'Tambah penugasan',
      children: [
        if (_musyrifah.isEmpty)
          const AdminEmptyCard(
            message:
                'Belum ada akun musyrifah aktif. Tetapkan role musyrifah di '
                'menu Pengguna & Peran.',
          ),
        if (_musyrifah.isEmpty) const SizedBox(height: 12),
        for (final assignment in _assignments) ...[
          Card(
            child: ListTile(
              leading: Icon(
                Icons.badge_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                assignment.userName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(assignment.branchName),
              trailing: IconButton(
                onPressed: () => _remove(assignment),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus penugasan',
                color: colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.repository,
    required this.musyrifah,
    required this.branches,
  });

  final AdminRepository repository;
  final List<AdminProfile> musyrifah;
  final List<BranchInfo> branches;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  late String? _userId;
  late String? _branchId;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userId = widget.musyrifah.isEmpty ? null : widget.musyrifah.first.id;
    _branchId = widget.branches.isEmpty ? null : widget.branches.first.id;
  }

  Future<void> _save() async {
    if (_isSaving || _userId == null || _branchId == null) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.assignStaff(
        userId: _userId!,
        branchId: _branchId!,
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
      title: const Text('Tambah Penugasan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _userId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Musyrifah'),
            items: [
              for (final profile in widget.musyrifah)
                DropdownMenuItem(
                  value: profile.id,
                  child: Text(
                    profile.fullName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _userId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _branchId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cabang'),
            items: [
              for (final branch in widget.branches)
                DropdownMenuItem(
                  value: branch.id,
                  child: Text(branch.name),
                ),
            ],
            onChanged: (value) => setState(() => _branchId = value),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
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
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tugaskan'),
        ),
      ],
    );
  }
}
