import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path == '/admin' || path == '/admin/dashboard') return 0;
    if (path.startsWith('/admin/orders')) return 1;
    if (path.startsWith('/admin/products')) return 2;
    if (path.startsWith('/admin/revenue')) return 3;
    if (path.startsWith('/admin/tickets')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final selected = _selectedIndex(context);

    final destinations = [
      (AppStrings.adminDashboard, '/admin'),
      (AppStrings.adminOrders, '/admin/orders'),
      (AppStrings.adminProducts, '/admin/products'),
      (AppStrings.adminRevenue, '/admin/revenue'),
      (AppStrings.adminTickets, '/admin/tickets'),
    ];

    if (isMobile) {
      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(destinations.length, (i) {
                final (label, path) = destinations[i];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected == i,
                    selectedColor: AppColors.accentLight,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.dashboard_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(AppStrings.adminPanel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ...List.generate(destinations.length, (i) {
                final (label, path) = destinations[i];
                return ListTile(
                  selected: selected == i,
                  selectedTileColor: AppColors.accentLight,
                  leading: Icon(
                    _iconFor(i),
                    color: selected == i ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                  title: Text(label),
                  onTap: () => context.go(path),
                );
              }),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  IconData _iconFor(int index) => switch (index) {
        0 => Icons.analytics_outlined,
        1 => Icons.receipt_long_outlined,
        2 => Icons.inventory_2_outlined,
        3 => Icons.bar_chart_outlined,
        4 => Icons.support_agent_outlined,
        _ => Icons.circle,
      };
}
