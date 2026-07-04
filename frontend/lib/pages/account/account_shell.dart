import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class AccountPageShell extends StatelessWidget {
  const AccountPageShell({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccountSidebar(),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSidebar extends StatelessWidget {
  const AccountSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final items = [
      (AppStrings.myProfile, '/account/profile', Icons.person_outline),
      (AppStrings.myOrders, '/account/orders', Icons.receipt_long_outlined),
      (AppStrings.myWishlist, '/account/wishlist', Icons.favorite_border),
      (AppStrings.myAddresses, '/account/addresses', Icons.location_on_outlined),
      (AppStrings.myTickets, '/account/tickets', Icons.support_agent_outlined),
      (AppStrings.notifications, '/account/notifications', Icons.notifications_outlined),
    ];

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.map((item) {
          final active = path == item.$2 || path.startsWith('${item.$2}/');
          return ListTile(
            leading: Icon(item.$3, color: active ? AppColors.primary : AppColors.textSecondary, size: 22),
            title: Text(
              item.$1,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textPrimary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: active,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () => context.go(item.$2),
          );
        }).toList(),
      ),
    );
  }
}
