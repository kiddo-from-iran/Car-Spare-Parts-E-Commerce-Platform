import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await context.read<ApiService>().getMyOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Padding(
      padding: EdgeInsets.all(AppResponsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.myOrders, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              TextButton(onPressed: () => context.go('/account/profile'), child: const Text(AppStrings.myProfile)),
              TextButton(onPressed: () => context.go('/account/addresses'), child: const Text(AppStrings.myAddresses)),
              TextButton(onPressed: () => context.go('/account/tickets'), child: const Text(AppStrings.myTickets)),
            ],
          ),
          const SizedBox(height: 24),
          if (_orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Text(AppStrings.noOrders, style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ..._orders.map((order) => _OrderCard(order: order)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('${AppStrings.orderStatus}: ${order.statusLabel}'),
            Text(AppStrings.formatPrice(order.total)),
          ],
        ),
        trailing: const Icon(Icons.arrow_back_ios, size: 16),
        onTap: () => context.go('/account/orders/${order.id}'),
      ),
    );
  }
}
