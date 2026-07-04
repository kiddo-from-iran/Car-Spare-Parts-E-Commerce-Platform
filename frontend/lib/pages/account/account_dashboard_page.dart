import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_data_table.dart';
import 'account_page_scaffold.dart';

class AccountDashboardPage extends StatefulWidget {
  const AccountDashboardPage({super.key});

  @override
  State<AccountDashboardPage> createState() => _AccountDashboardPageState();
}

class _AccountDashboardPageState extends State<AccountDashboardPage> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await context.read<ApiService>().getMyOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  int get _activeCount => _orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').length;

  @override
  Widget build(BuildContext context) {
    const columns = [
      AdminTableColumn(label: 'ردیف', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'شماره سفارش', flex: 3, align: TextAlign.start),
      AdminTableColumn(label: 'تاریخ', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'مبلغ', flex: 2, align: TextAlign.start),
      AdminTableColumn(label: 'وضعیت', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'عملیات', flex: 1, align: TextAlign.center),
    ];

    final rows = _orders.asMap().entries.map((entry) {
      final index = entry.key;
      final order = entry.value;
      return [
        Text('${index + 1}', textAlign: TextAlign.center),
        Text(order.orderNumber, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(_formatDate(order.createdAt), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        Text(AppStrings.formatPrice(order.total), textAlign: TextAlign.start),
        _OrderStatusChip(label: order.statusLabel, status: order.status),
        IconButton(
          tooltip: 'جزئیات سفارش',
          visualDensity: VisualDensity.compact,
          onPressed: () => context.go('/account/orders/${order.id}'),
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
      ];
    }).toList();

    return AccountPageScaffold(
      title: AppStrings.userDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loading) ...[
            Row(
              children: [
                Expanded(
                  child: AccountStatCard(
                    label: 'کل سفارش‌ها',
                    value: '${_orders.length}',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AccountStatCard(
                    label: 'سفارش‌های در جریان',
                    value: '$_activeCount',
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: _loading,
              emptyMessage: AppStrings.noOrders,
              cellPadding: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) => iso.isEmpty ? '—' : iso.split('T').first;
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'delivered' => AppColors.success,
      'cancelled' => AppColors.error,
      'processing' || 'shipped' => AppColors.warning,
      _ => AppColors.gold,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
