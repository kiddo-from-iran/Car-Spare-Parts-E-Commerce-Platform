import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminTicketsPage extends StatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  State<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends State<AdminTicketsPage> {
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tickets = await context.read<ApiService>().getAdminTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.adminTickets, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_tickets.isEmpty)
            Text(AppStrings.noTickets, style: TextStyle(color: AppColors.textMuted))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = _tickets[index];
                  return ListTile(
                    tileColor: AppColors.creamLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(t.subject),
                    subtitle: Text('${t.userName} · ${t.orderNumber} · ${t.status == 'open' ? 'باز' : 'بسته'}'),
                    trailing: const Icon(Icons.arrow_back_ios, size: 16),
                    onTap: () => context.go('/admin/tickets/${t.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AdminTicketDetailPage extends StatefulWidget {
  const AdminTicketDetailPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<AdminTicketDetailPage> createState() => _AdminTicketDetailPageState();
}

class _AdminTicketDetailPageState extends State<AdminTicketDetailPage> {
  Ticket? _ticket;
  bool _loading = true;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ticket = await context.read<ApiService>().getAdminTicket(widget.ticketId);
      if (mounted) setState(() => _ticket = ticket);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    final ticket = await context.read<ApiService>().replyToTicket(
          widget.ticketId,
          _replyController.text.trim(),
          admin: true,
        );
    _replyController.clear();
    if (mounted) setState(() => _ticket = ticket);
  }

  Future<void> _close() async {
    final ticket = await context.read<ApiService>().closeTicket(widget.ticketId);
    if (mounted) setState(() => _ticket = ticket);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final ticket = _ticket;
    if (ticket == null) return Center(child: Text(AppStrings.noTickets));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(ticket.subject, style: Theme.of(context).textTheme.headlineSmall)),
              if (ticket.status == 'open')
                OutlinedButton(onPressed: _close, child: const Text(AppStrings.closeTicket)),
            ],
          ),
          Text('${ticket.userName} · ${ticket.orderNumber}'),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: ticket.messages.map((m) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: m.isAdmin ? AppColors.creamDark : AppColors.creamLight,
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
              )).toList(),
            ),
          ),
          if (ticket.status == 'open') ...[
            TextField(
              controller: _replyController,
              decoration: const InputDecoration(labelText: AppStrings.reply),
              maxLines: 3,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _sendReply, child: const Text(AppStrings.send)),
          ],
        ],
      ),
    );
  }
}
