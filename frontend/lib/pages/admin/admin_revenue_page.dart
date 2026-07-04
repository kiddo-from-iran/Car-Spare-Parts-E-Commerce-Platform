import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_bar_chart.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({super.key});

  @override
  State<AdminRevenuePage> createState() => _AdminRevenuePageState();
}

class _AdminRevenuePageState extends State<AdminRevenuePage> {
  RevenueSummary? _summary;
  List<Order> _orders = [];
  List<OrderStatusOption> _statuses = [];
  bool _loading = true;

  String _period = 'monthly';
  String _statusFilter = '';
  final _search = TextEditingController();
  String _query = '';
  double? _minTotal;
  double? _maxTotal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final months = switch (_period) {
        'yearly' => 12,
        'monthly' => 6,
        _ => 6,
      };
      final results = await Future.wait([
        api.getRevenueSummary(months: months),
        api.getAdminOrders(filter: 'all'),
        api.getOrderStatuses(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as RevenueSummary;
          _orders = results[1] as List<Order>;
          _statuses = results[2] as List<OrderStatusOption>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Order> get _filteredOrders {
    final q = _query.trim().toLowerCase();
    return _orders.where((o) {
      if (_statusFilter.isNotEmpty && o.status != _statusFilter) return false;
      if (_minTotal != null && o.total < _minTotal!) return false;
      if (_maxTotal != null && o.total > _maxTotal!) return false;
      if (_period == 'daily') {
        final today = DateTime.now().toIso8601String().split('T').first;
        if (!o.createdAt.startsWith(today)) return false;
      }
      if (q.isEmpty) return true;
      return o.orderNumber.toLowerCase().contains(q) ||
          o.userName.toLowerCase().contains(q) ||
          o.items.any((i) => i.productName.toLowerCase().contains(q));
    }).toList();
  }

  List<({String name, int qty, double revenue})> get _bestSellers {
    final map = <int, ({String name, int qty, double revenue})>{};
    for (final order in _orders.where((o) => o.status != 'cancelled')) {
      for (final item in order.items) {
        final cur = map[item.productId];
        if (cur == null) {
          map[item.productId] = (name: item.productName, qty: item.quantity, revenue: item.lineTotal);
        } else {
          map[item.productId] = (
            name: cur.name,
            qty: cur.qty + item.quantity,
            revenue: cur.revenue + item.lineTotal,
          );
        }
      }
    }
    final list = map.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
    return list.take(10).toList();
  }

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await context.read<ApiService>().updateOrderStatus(order.id, status);
      if (mounted) {
        context.read<ToastProvider>().show('وضعیت به‌روز شد');
        _load();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final filtered = _filteredOrders;
    final best = _bestSellers;

    return AdminPageScaffold(
      title: AppStrings.adminRevenue,
      scrollable: true,
      child: _loading
          ? const AppLoadingCenter()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(title: AppStrings.revenueTotal, value: AppStrings.formatPrice(summary?.totalRevenue ?? 0)),
                    _StatCard(title: AppStrings.orderCount, value: '${summary?.totalOrders ?? 0}'),
                    _StatCard(title: 'سفارش‌های فیلتر شده', value: '${filtered.length}'),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  children: [
                    _periodChip('روزانه', 'daily'),
                    _periodChip('ماهانه', 'monthly'),
                    _periodChip('سالانه', 'yearly'),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth > 900;
                    return Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AdminBarChart(
                            title: 'درآمد ماهانه',
                            labels: (summary?.months ?? []).map((m) => m.monthLabel).toList().reversed.toList(),
                            values: (summary?.months ?? []).map((m) => m.revenue).toList().reversed.toList(),
                            valueFormatter: (v) => AppStrings.formatPrice(v),
                          ),
                        ),
                        SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                        Expanded(
                          child: AdminBarChart(
                            title: 'تعداد سفارش ماهانه',
                            labels: (summary?.months ?? []).map((m) => m.monthLabel).toList().reversed.toList(),
                            values: (summary?.months ?? []).map((m) => m.orderCount.toDouble()).toList().reversed.toList(),
                            barColor: AppColors.black,
                            valueFormatter: (v) => v.toStringAsFixed(0),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _BestSellersList(items: best),
                const SizedBox(height: 24),
                AdminSearchBar(
                  controller: _search,
                  hint: 'جستجو در گزارش فروش...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DropdownButton<String>(
                      hint: const Text('وضعیت سفارش'),
                      value: _statusFilter.isEmpty ? null : _statusFilter,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('همه')),
                        ..._statuses.map((s) => DropdownMenuItem(value: s.value, child: Text(s.label))),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v ?? ''),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'حداقل مبلغ', isDense: true),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _minTotal = double.tryParse(v)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'حداکثر مبلغ', isDense: true),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _maxTotal = double.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 520,
                  child: AdminDataTable(
                    columns: const [
                      AdminTableColumn(label: 'ردیف', flex: 1, minWidth: 50, align: TextAlign.center),
                      AdminTableColumn(label: 'شماره سفارش', flex: 2, minWidth: 110),
                      AdminTableColumn(label: 'مشتری', flex: 2, minWidth: 110),
                      AdminTableColumn(label: 'محصول', flex: 3, minWidth: 130),
                      AdminTableColumn(label: 'تعداد', flex: 1, minWidth: 60, align: TextAlign.center),
                      AdminTableColumn(label: 'مبلغ', flex: 2, minWidth: 90),
                      AdminTableColumn(label: 'تاریخ', flex: 2, minWidth: 90),
                      AdminTableColumn(label: 'وضعیت', flex: 2, minWidth: 140),
                    ],
                    rows: filtered.asMap().entries.map((entry) {
                      final i = entry.key;
                      final o = entry.value;
                      final first = o.items.isNotEmpty ? o.items.first : null;
                      return [
                        Text('${i + 1}', textAlign: TextAlign.center),
                        Text(o.orderNumber),
                        Text(o.userName, style: const TextStyle(fontSize: 12)),
                        Text(first?.productName ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        Text('${first?.quantity ?? 0}', textAlign: TextAlign.center),
                        Text(AppStrings.formatPrice(o.total)),
                        Text(o.createdAt.split('T').first, style: const TextStyle(fontSize: 12)),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: o.status,
                            isExpanded: true,
                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            items: _statuses.map((s) => DropdownMenuItem(value: s.value, child: Text(s.label, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) {
                              if (v != null) _updateStatus(o, v);
                            },
                          ),
                        ),
                      ];
                    }).toList(),
                    emptyMessage: AppStrings.noOrders,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _periodChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _period == value,
      onSelected: (_) {
        setState(() => _period = value);
        _load();
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BestSellersList extends StatelessWidget {
  const _BestSellersList({required this.items});

  final List<({String name, int qty, double revenue})> items;

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
          Text('پرفروش‌ترین محصولات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('داده‌ای موجود نیست', style: TextStyle(color: AppColors.textMuted))
          else
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(items[i].name)),
                    Text('${items[i].qty} فروش', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(AppStrings.formatPrice(items[i].revenue), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
