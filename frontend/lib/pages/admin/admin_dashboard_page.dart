import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await context.read<ApiService>().getAdminStats();
      if (mounted) setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final s = _stats ?? {};
    final cards = [
      ('فروش کل', s['total_sales'], Icons.payments_outlined, AppColors.primary),
      ('فروش امروز', s['today_sales'], Icons.today_outlined, AppColors.success),
      ('فروش ماه', s['month_sales'], Icons.calendar_month_outlined, AppColors.accent),
      ('کل سفارش‌ها', s['total_orders'], Icons.receipt_long_outlined, AppColors.navy),
      ('سفارش‌های در انتظار', s['pending_orders'], Icons.hourglass_empty, AppColors.warning),
      ('سفارش‌های تکمیل‌شده', s['completed_orders'], Icons.check_circle_outline, AppColors.success),
      ('مشتریان', s['total_customers'], Icons.people_outline, AppColors.primaryLight),
      ('محصولات', s['total_products'], Icons.inventory_2_outlined, AppColors.textSecondary),
      ('موجودی کم', s['low_stock_products'], Icons.warning_amber_outlined, AppColors.warning),
      ('ناموجود', s['out_of_stock_products'], Icons.remove_shopping_cart_outlined, AppColors.error),
      ('تیکت‌های باز', s['open_tickets'], Icons.support_agent_outlined, AppColors.discount),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.adminDashboard, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final (label, value, icon, color) = cards[i];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const Spacer(),
                    Text(
                      value is num && label.contains('فروش')
                          ? AppStrings.formatPrice(value.toDouble())
                          : '${value ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
