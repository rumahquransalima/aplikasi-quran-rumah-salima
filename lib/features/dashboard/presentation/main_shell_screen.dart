import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../auth/domain/app_user.dart';
import '../../history/presentation/history_tab.dart';
import '../../profile/presentation/profile_tab.dart';
import '../../progress/presentation/progress_tab.dart';
import 'home_tab.dart';

/// Shell utama setelah login dengan empat tab sesuai technical guidelines.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tabFadeController;
  late final Animation<double> _tabFade;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabFadeController = AnimationController(
      vsync: this,
      duration: AppMotion.base,
      value: 1,
    );
    _tabFade = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _tabFadeController, curve: AppMotion.standard),
    );
  }

  @override
  void dispose() {
    _tabFadeController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
    if (AppMotion.isReduced(context)) {
      _tabFadeController.value = 1;
    } else {
      _tabFadeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _tabFade,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeTab(user: widget.user, onOpenTab: _selectTab),
            ProgressTab(user: widget.user),
            HistoryTab(user: widget.user),
            ProfileTab(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: _SalimaBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }
}

class _SalimaBottomNav extends StatelessWidget {
  const _SalimaBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    _NavItemData(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Perkembangan',
    ),
    _NavItemData(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: 'Riwayat',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D13382D),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _NavButton(
                    data: _items[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      label: data.label,
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: 22,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: selected ? 14 : 4,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
