import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/admin/admin_page_scaffold.dart';

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
    setState(() => _loading = true);
    try {
      final stats = await context.read<ApiService>().getAdminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingCenter();
    }

    final s = _stats ?? {};
    final cards = [
      ('فروش کل', _money(s['total_sales']), Icons.payments_outlined, AppColors.gold),
      ('فروش امروز', _money(s['today_sales']), Icons.today_outlined, AppColors.black),
      ('فروش ماه', _money(s['month_sales']), Icons.calendar_month_outlined, AppColors.goldDark),
      ('کل سفارش‌ها', '${s['total_orders'] ?? 0}', Icons.receipt_long_outlined, AppColors.blackLight),
      ('در انتظار', '${s['pending_orders'] ?? 0}', Icons.hourglass_empty, AppColors.warning),
      ('در حال پردازش', '${s['processing_orders'] ?? 0}', Icons.sync, AppColors.gold),
      ('در حال ارسال', '${s['in_transit_orders'] ?? 0}', Icons.local_shipping_outlined, AppColors.black),
      ('تحویل شده', '${s['completed_orders'] ?? 0}', Icons.check_circle_outline, AppColors.success),
      ('لغو شده', '${s['cancelled_orders'] ?? 0}', Icons.cancel_outlined, AppColors.error),
      ('مشتریان', '${s['total_customers'] ?? 0}', Icons.people_outline, AppColors.gold),
      ('محصولات', '${s['total_products'] ?? 0}', Icons.inventory_2_outlined, AppColors.black),
      ('موجودی کم', '${s['low_stock_products'] ?? 0}', Icons.warning_amber_outlined, AppColors.warning),
    ];

    final recentOrders = (s['recent_orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pendingTickets = (s['pending_tickets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final lowStock = (s['low_stock_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return AdminPageScaffold(
      title: AppStrings.adminDashboard,
      scrollable: true,
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.55,
            ),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final (label, value, icon, color) = cards[i];
              return AdminStatCard(label: label, value: value, icon: icon, color: color);
            },
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 900;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TaskPanel(
                    title: 'سفارش‌های اخیر',
                    empty: 'سفارشی نیست',
                    items: recentOrders.map((o) => _TaskItem(
                      title: o['order_number']?.toString() ?? '',
                      subtitle: '${o['user_name']} · ${AppStrings.formatPrice((o['total'] as num?)?.toDouble() ?? 0)}',
                      trailing: o['status_label']?.toString() ?? '',
                      onTap: () => context.go('/admin/orders'),
                    )).toList(),
                  )),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  Expanded(child: _TaskPanel(
                    title: 'تیکت‌های در انتظار پاسخ',
                    empty: 'تیکت بازی نیست',
                    items: pendingTickets.map((t) => _TaskItem(
                      title: t['subject']?.toString() ?? '',
                      subtitle: t['user_name']?.toString() ?? '',
                      trailing: 'باز',
                      onTap: () => context.go('/admin/tickets/${t['id']}'),
                    )).toList(),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _TaskPanel(
            title: 'محصولات با موجودی کم',
            empty: 'همه محصولات موجود هستند',
            items: lowStock.map((p) => _TaskItem(
              title: p['name']?.toString() ?? '',
              subtitle: 'موجودی: ${p['stock_quantity'] ?? 0}',
              trailing: AppStrings.formatPrice((p['price'] as num?)?.toDouble() ?? 0),
              onTap: () => context.go('/admin/products'),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _money(dynamic v) => AppStrings.formatPrice((v as num?)?.toDouble() ?? 0);
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({required this.title, required this.items, required this.empty});

  final String title;
  final List<_TaskItem> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(empty, style: TextStyle(color: AppColors.textMuted))
          else
            for (final item in items) item,
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
