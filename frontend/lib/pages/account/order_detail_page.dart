import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../models/ticket.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final order = _order;
    if (order == null) {
      return Center(child: Text(AppStrings.noOrders));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/account/orders'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text(AppStrings.myOrders),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.orderDetails, style: Theme.of(context).textTheme.headlineSmall),
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
            ElevatedButton(onPressed: _createTicket, child: const Text(AppStrings.send)),
          ],
        ),
      ),
    );
  }
}

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tickets = await context.read<ApiService>().getMyTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.myTickets, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (_tickets.isEmpty)
            Text(AppStrings.noTickets, style: TextStyle(color: AppColors.textMuted))
          else
            ..._tickets.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(t.subject),
                  subtitle: Text('${t.orderNumber} · ${t.status == 'open' ? 'باز' : 'بسته'}'),
                  trailing: const Icon(Icons.arrow_back_ios, size: 16),
                  onTap: () => context.go('/account/tickets/${t.id}'),
                ),
              ),
            ),
        ],
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
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final ticket = _ticket;
    if (ticket == null) return Center(child: Text(AppStrings.noTickets));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.subject, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
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
              ElevatedButton(onPressed: _sendReply, child: const Text(AppStrings.send)),
            ],
          ],
        ),
      ),
    );
  }
}
