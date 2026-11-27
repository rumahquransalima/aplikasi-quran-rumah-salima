import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../data/admin_repository.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_scaffold.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  late final AdminRepository _repository;
  List<AdminStudent> _students = const [];
  List<AdminProfile> _profiles = const [];
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
      final profiles = await _repository.fetchProfiles();
      final students = await _repository.fetchStudents();
      if (mounted) {
        setState(() {
          _branches = branches;
          _profiles = profiles;
          _students = students;
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

  List<AdminProfile> _accountOptions(AdminStudent? student) {
    final linkedToOther = {
      for (final item in _students)
        if (item.userId != null && item.id != student?.id) item.userId!,
    };

    return _profiles
        .where(
          (profile) =>
              profile.role == UserRole.mahasantri &&
              (!linkedToOther.contains(profile.id) ||
                  profile.id == student?.userId),
        )
        .toList(growable: false);
  }

  Future<void> _openEditor([AdminStudent? student]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StudentDialog(
        repository: _repository,
        student: student,
        branches: _branches.where((branch) => branch.isActive).toList(),
        accountOptions: _accountOptions(student),
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
    final profileById = {for (final p in _profiles) p.id: p};

    return AdminListScaffold(
      title: 'Mahasantri',
      subtitle:
          'Tautkan akun agar mahasantri dapat melihat penilaian pribadi. Satu '
          'akun hanya boleh terhubung ke satu baris mahasantri.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      emptyMessage: 'Belum ada mahasantri. Tambahkan data santri terlebih dahulu.',
      onAdd: _branches.isEmpty ? null : () => _openEditor(),
      addTooltip: 'Tambah mahasantri',
      children: [
        for (final student in _students) ...[
          Card(
            child: ListTile(
              onTap: () => _openEditor(student),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  student.fullName.isEmpty
                      ? '?'
                      : student.fullName[0].toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                student.fullName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                [
                  student.nis ?? 'Tanpa NIS',
                  student.branchName,
                  student.userId == null
                      ? 'Akun belum tertaut'
                      : (profileById[student.userId]?.email ??
                            'Akun tertaut'),
                  if (!student.isActive) 'Nonaktif',
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                student.userId == null
                    ? Icons.link_off_rounded
                    : Icons.link_rounded,
                color: student.userId == null
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StudentDialog extends StatefulWidget {
  const _StudentDialog({
    required this.repository,
    required this.branches,
    required this.accountOptions,
    this.student,
  });

  final AdminRepository repository;
  final List<BranchInfo> branches;
  final List<AdminProfile> accountOptions;
  final AdminStudent? student;

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

const String _noAccount = '__no_account__';

class _StudentDialogState extends State<_StudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nisController;
  late String? _branchId;
  late String? _userId;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.student?.fullName ?? '',
    );
    _nisController = TextEditingController(text: widget.student?.nis ?? '');
    _branchId = widget.student?.branchId ??
        (widget.branches.isEmpty ? null : widget.branches.first.id);
    _userId = widget.student?.userId;
    _isActive = widget.student?.isActive ?? true;

    if (_userId != null &&
        !widget.accountOptions.any((option) => option.id == _userId)) {
      _userId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_branchId == null) {
      setState(() => _errorMessage = 'Cabang wajib dipilih.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await widget.repository.updateStudent(
          id: widget.student!.id,
          fullName: _nameController.text,
          nis: _nisController.text,
          branchId: _branchId!,
          isActive: _isActive,
          userId: _userId,
        );
      } else {
        await widget.repository.createStudent(
          fullName: _nameController.text,
          nis: _nisController.text,
          branchId: _branchId!,
          userId: _userId,
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
      title: Text(_isEditing ? 'Ubah Mahasantri' : 'Tambah Mahasantri'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().length < 3)
                      ? 'Nama minimal 3 karakter.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nisController,
                  decoration: const InputDecoration(
                    labelText: 'NIS (opsional)',
                  ),
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _userId ?? _noAccount,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Akun mahasantri (opsional)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: _noAccount,
                      child: Text('Tanpa akun'),
                    ),
                    for (final profile in widget.accountOptions)
                      DropdownMenuItem(
                        value: profile.id,
                        child: Text(
                          profile.email == null
                              ? profile.fullName
                              : '${profile.fullName} • ${profile.email}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _userId = value == _noAccount ? null : value,
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mahasantri aktif'),
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
