import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class AccountShell extends StatelessWidget {
  const AccountShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path == '/account' || path.startsWith('/account/orders')) return 0;
    if (path.startsWith('/account/profile') || path.startsWith('/account/addresses')) return 1;
    if (path.startsWith('/account/tickets')) return 2;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final selected = _selectedIndex(context);

    const destinations = [
      (AppStrings.userDashboard, '/account', Icons.dashboard_outlined),
      (AppStrings.userProfile, '/account/profile', Icons.person_outline),
      (AppStrings.myTickets, '/account/tickets', Icons.support_agent_outlined),
    ];

    if (isMobile) {
      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(destinations.length, (i) {
                final (label, path, _) = destinations[i];
                final active = selected == i;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: active,
                    selectedColor: AppColors.gold.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: active ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(color: active ? AppColors.gold : AppColors.border),
                    onSelected: (_) => context.go(path),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 240,
          decoration: const BoxDecoration(color: AppColors.black),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.account,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark,
                            ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < destinations.length; i++)
                  _AccountNavTile(
                    label: destinations[i].$1,
                    path: destinations[i].$2,
                    icon: destinations[i].$3,
                    active: selected == i,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.background,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _AccountNavTile extends StatelessWidget {
  const _AccountNavTile({
    required this.label,
    required this.path,
    required this.icon,
    required this.active,
  });

  final String label;
  final String path;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: active,
      selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
      leading: Icon(
        icon,
        color: active ? AppColors.gold : AppColors.textOnDark.withValues(alpha: 0.65),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.gold : AppColors.textOnDark.withValues(alpha: 0.85),
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () => context.go(path),
    );
  }
}
