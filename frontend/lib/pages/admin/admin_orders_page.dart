import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page_scaffold.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Order> _orders = [];
  List<OrderStatusOption> _statuses = [];
  bool _loading = true;

  final _search = TextEditingController();
  String _query = '';
  String _statusFilter = '';
  String _filter = 'all';
  double? _minPrice;
  double? _maxPrice;

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
      final results = await Future.wait([
        api.getAdminOrders(filter: _filter == 'all' ? null : _filter),
        api.getOrderStatuses(),
      ]);
      if (mounted) {
        setState(() {
          _orders = results[0] as List<Order>;
          _statuses = results[1] as List<OrderStatusOption>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Order> get _filtered {
    final q = _query.trim().toLowerCase();
    return _orders.where((o) {
      if (_statusFilter.isNotEmpty && o.status != _statusFilter) return false;
      if (_minPrice != null && o.total < _minPrice!) return false;
      if (_maxPrice != null && o.total > _maxPrice!) return false;
      if (q.isEmpty) return true;
      final products = o.items.map((i) => i.productName).join(' ');
      return o.orderNumber.toLowerCase().contains(q) ||
          o.userName.toLowerCase().contains(q) ||
          o.userPhone.contains(q) ||
          o.city.toLowerCase().contains(q) ||
          o.state.toLowerCase().contains(q) ||
          products.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await context.read<ApiService>().updateOrderStatus(order.id, status);
      if (mounted) {
        context.read<ToastProvider>().show('وضعیت سفارش به‌روز شد');
        _load();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سفارش'),
        content: Text('آیا از حذف سفارش ${order.orderNumber} مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<ApiService>().deleteOrder(order.id);
      if (mounted) {
        context.read<ToastProvider>().show('سفارش حذف شد');
        _load();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  void _showDetails(Order order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سفارش ${order.orderNumber}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${order.userName} · ${order.userPhone}'),
                Text('${order.city}، ${order.state}'),
                Text(order.address),
                const Divider(),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${item.productName} × ${item.quantity} — ${AppStrings.formatPrice(item.lineTotal)}'),
                  ),
                const Divider(),
                Text('${AppStrings.total}: ${AppStrings.formatPrice(order.total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    const columns = [
      AdminTableColumn(label: 'ردیف', flex: 1, minWidth: 50, align: TextAlign.center),
      AdminTableColumn(label: 'شماره سفارش', flex: 2, minWidth: 120),
      AdminTableColumn(label: 'مشتری', flex: 2, minWidth: 120),
      AdminTableColumn(label: 'محصولات', flex: 3, minWidth: 140),
      AdminTableColumn(label: 'مبلغ', flex: 2, minWidth: 100),
      AdminTableColumn(label: 'تاریخ', flex: 2, minWidth: 100),
      AdminTableColumn(label: 'وضعیت', flex: 2, minWidth: 140),
      AdminTableColumn(label: 'عملیات', flex: 3, minWidth: 160, align: TextAlign.center),
    ];

    final rows = filtered.asMap().entries.map((entry) {
      final i = entry.key;
      final o = entry.value;
      final productSummary = o.items.map((e) => e.productName).take(2).join('، ');
      return [
        Text('${i + 1}', textAlign: TextAlign.center),
        Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${o.userName}\n${o.userPhone}', style: const TextStyle(fontSize: 12)),
        Text(productSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
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
        Wrap(
          spacing: 0,
          children: [
            IconButton(tooltip: 'جزئیات', onPressed: () => _showDetails(o), icon: const Icon(Icons.visibility_outlined, size: 20)),
            IconButton(
              tooltip: 'تماس',
              onPressed: () => launchUrl(Uri.parse('tel:${o.userPhone}')),
              icon: const Icon(Icons.phone_outlined, size: 20),
            ),
            IconButton(tooltip: 'حذف', onPressed: () => _deleteOrder(o), icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error)),
          ],
        ),
      ];
    }).toList();

    return AdminPageScaffold(
      title: AppStrings.adminOrders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSearchBar(
            controller: _search,
            hint: 'جستجو: شماره سفارش، مشتری، محصول، شهر...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('همه', 'all'),
              _chip(AppStrings.activeOrders, 'active'),
              _chip(AppStrings.completedOrders, 'completed'),
              DropdownButton<String>(
                hint: const Text('وضعیت'),
                value: _statusFilter.isEmpty ? null : _statusFilter,
                items: [
                  const DropdownMenuItem(value: '', child: Text('همه وضعیت‌ها')),
                  ..._statuses.map((s) => DropdownMenuItem(value: s.value, child: Text(s.label))),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? ''),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'حداقل قیمت', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _minPrice = double.tryParse(v)),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'حداکثر قیمت', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _maxPrice = double.tryParse(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: _loading,
              emptyMessage: AppStrings.noOrders,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
    );
  }
}
