import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../models/ticket.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';
import 'account_page_scaffold.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final order = await context.read<ApiService>().getMyOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createTicket() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) return;
    try {
      final ticket = await context.read<ApiService>().createTicket(
            widget.orderId,
            _subject.text.trim(),
            _message.text.trim(),
          );
      if (!mounted) return;
      context.go('/account/tickets/${ticket.id}');
    } catch (e) {
      if (mounted) {
        if (mounted) context.showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AccountPageScaffold(
        title: AppStrings.orderDetails,
        child: AppLoadingCenter(size: 72),
      );
    }
    final order = _order;
    if (order == null) {
      return AccountPageScaffold(
        title: AppStrings.orderDetails,
        child: Center(child: Text(AppStrings.noOrders)),
      );
    }

    return AccountPageScaffold(
      title: AppStrings.orderDetails,
      scrollable: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/account'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text(AppStrings.userDashboard),
            ),
            const SizedBox(height: 8),
            Text('${AppStrings.orderNumber}: ${order.orderNumber}'),
            const SizedBox(height: 4),
            Chip(label: Text(order.statusLabel)),
            const SizedBox(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.productName} × ${item.quantity}')),
                    Text(AppStrings.formatPrice(item.lineTotal)),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.total, style: Theme.of(context).textTheme.titleMedium),
                Text(AppStrings.formatPrice(order.total)),
              ],
            ),
            const SizedBox(height: 32),
            Text(AppStrings.openTicket, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: AppStrings.ticketSubject),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              decoration: const InputDecoration(labelText: AppStrings.ticketMessage),
              maxLines: 3,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _createTicket,
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textOnGold),
              child: const Text(AppStrings.send),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Ticket? _ticket;
  bool _loading = true;
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ticket = await context.read<ApiService>().getMyTicket(widget.ticketId);
      if (mounted) setState(() => _ticket = ticket);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendReply() async {
    if (_reply.text.trim().isEmpty) return;
    try {
      final ticket = await context.read<ApiService>().replyToTicket(widget.ticketId, _reply.text.trim());
      _reply.clear();
      if (mounted) setState(() => _ticket = ticket);
    } catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AccountPageScaffold(
        title: AppStrings.myTickets,
        child: AppLoadingCenter(size: 72),
      );
    }
    final ticket = _ticket;
    if (ticket == null) {
      return AccountPageScaffold(
        title: AppStrings.myTickets,
        child: Center(child: Text(AppStrings.noTickets)),
      );
    }

    return AccountPageScaffold(
      title: ticket.subject,
      scrollable: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/account/tickets'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text(AppStrings.myTickets),
            ),
            const SizedBox(height: 8),
            ...ticket.messages.map(
              (m) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: m.isAdmin ? AppColors.cream : AppColors.creamLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(m.message),
                  ],
                ),
              ),
            ),
            if (ticket.status == 'open') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reply,
                decoration: const InputDecoration(labelText: AppStrings.reply),
                maxLines: 3,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sendReply,
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textOnGold),
                child: const Text(AppStrings.send),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
