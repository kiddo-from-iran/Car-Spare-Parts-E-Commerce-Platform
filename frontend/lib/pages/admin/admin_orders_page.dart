import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _filter = 'active';
  List<Order> _orders = [];
  List<OrderStatusOption> _statuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await context.read<ApiService>().updateOrderStatus(order.id, status);
      _load();
    } catch (e) {
      if (mounted) {
        context.showError('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.adminOrders, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(label: AppStrings.activeOrders, value: 'active', group: _filter, onSelect: (v) {
                _filter = v;
                _load();
              }),
              _FilterChip(label: AppStrings.completedOrders, value: 'completed', group: _filter, onSelect: (v) {
                _filter = v;
                _load();
              }),
              _FilterChip(label: AppStrings.allOrders, value: 'all', group: _filter, onSelect: (v) {
                _filter = v;
                _load();
              }),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_orders.isEmpty)
            Text(AppStrings.noOrders, style: TextStyle(color: AppColors.textMuted))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${order.userName} · ${order.userPhone}'),
                                    Text(AppStrings.formatPrice(order.total)),
                                  ],
                                ),
                              ),
                              Chip(label: Text(order.statusLabel)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('${AppStrings.changeStatus}:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: order.status,
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                  items: _statuses
                                      .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) _updateStatus(order, v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.group,
    required this.onSelect,
  });

  final String label;
  final String value;
  final String group;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: group == value,
      onSelected: (_) => onSelect(value),
    );
  }
}
