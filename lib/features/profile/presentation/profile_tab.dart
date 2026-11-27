import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/islamic_pattern.dart';
import '../../../core/widgets/section_header.dart';
import '../../admin/presentation/admin_hub_screen.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_exception.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.user});

  final AppUser user;

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar dari Akun?'),
          content: const Text(
            'Anda perlu masuk kembali untuk mengakses data penilaian.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !context.mounted) {
      return;
    }

    try {
      await context.read<AuthCubit>().signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal keluar. Periksa koneksi internet Anda.'),
          ),
        );
      }
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _ProfileHero(
            user: user,
            onEdit: () => _editProfile(context),
            onRefresh: () => context.read<AuthCubit>().refreshProfile(),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Informasi Akun',
            subtitle: 'Data profil yang tersimpan di Supabase.',
            compact: true,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nama lengkap',
                  value: user.fullName,
                ),
                const Divider(height: 1),
                _ProfileRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: user.email ?? '-',
                ),
                const Divider(height: 1),
                _ProfileRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: user.phone ?? '-',
                ),
                const Divider(height: 1),
                _ProfileRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Peran',
                  value: user.role.label,
                ),
                const Divider(height: 1),
                _ProfileRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Status akun',
                  value: user.isActive ? 'Aktif' : 'Tidak aktif',
                ),
                if (user.isMahasantri) ...[
                  const Divider(height: 1),
                  _ProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'NIS',
                    value: user.studentNis ?? 'Belum terhubung',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Akses Cabang',
            subtitle: 'Cabang yang dapat Anda lihat dan kelola.',
            compact: true,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user.branches.isEmpty
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.isAdmin
                                ? 'Belum ada cabang aktif di database.'
                                : 'Belum ada cabang yang ditugaskan. Hubungi '
                                      'admin untuk penugasan.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        for (final branch in user.branches) ...[
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_tree_outlined,
                                  size: 17,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!branch.isActive)
                                _SmallBadge(
                                  label: 'Nonaktif',
                                  color: colorScheme.errorContainer,
                                  textColor: colorScheme.onErrorContainer,
                                ),
                            ],
                          ),
                          if (branch != user.branches.last)
                            const Divider(height: 20),
                        ],
                      ],
                    ),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Administrasi',
              subtitle: 'Akses khusus pengelola data.',
              compact: true,
            ),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_outlined,
                    size: 20,
                    color: AppColors.goldInk,
                  ),
                ),
                title: const Text('Manajemen Data & Audit Log'),
                subtitle: const Text(
                  'Cabang, mahasantri, pengguna, penugasan, periode, dan log.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminHubScreen(user: user),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari Akun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(
                color: colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Versi 1.0.0 • Supabase Cloud',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onEdit,
    required this.onRefresh,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.liftedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IslamicPattern(
                color: AppColors.gold,
                opacity: 0.09,
                spacing: 52,
              ),
            ),
            Positioned(
              top: -44,
              right: -32,
              child: SizedBox(
                width: 152,
                height: 220,
                child: MihrabArch(
                  color: AppColors.gold,
                  opacity: 0.16,
                  strokeWidth: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Profil',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.cream,
                          fontSize: 24,
                          height: 1.1,
                        ),
                      ),
                      const Spacer(),
                      _HeroAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Ubah profil',
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _HeroAction(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Muat ulang profil',
                        onTap: onRefresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 1.6),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.cream,
                          child: Text(
                            user.initials,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.emeraldDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.cream,
                                fontSize: 21,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'Email tidak tersedia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.cream.withValues(alpha: 0.72),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                user.role.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.emeraldDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: CircleBorder(
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: AppColors.cream),
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});

  final AppUser user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
      await context.read<AuthCubit>().updateProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AuthRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Profil gagal diperbarui.');
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
      title: const Text('Ubah Profil'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: Validators.fullName,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor telepon (opsional)',
              ),
              validator: Validators.optionalPhone,
            ),
            const SizedBox(height: 10),
            Text(
              'Email, role, dan status aktif hanya dapat diubah oleh admin.',
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
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
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 19, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
