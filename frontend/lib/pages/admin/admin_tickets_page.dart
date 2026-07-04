import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminTicketsPage extends StatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  State<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends State<AdminTicketsPage> {
  List<Ticket> _tickets = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

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
      final tickets = await context.read<ApiService>().getAdminTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Ticket> get _filtered {
    final q = _query.trim().toLowerCase();
    return _tickets.where((t) {
      if (_statusFilter == 'open' && t.status != 'open') return false;
      if (_statusFilter == 'closed' && t.status != 'closed') return false;
      if (q.isEmpty) return true;
      return t.subject.toLowerCase().contains(q) ||
          t.userName.toLowerCase().contains(q) ||
          t.orderNumber.toLowerCase().contains(q) ||
          t.id.toString().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    const columns = [
      AdminTableColumn(label: 'ردیف', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'آیدی', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'موضوع', flex: 4, align: TextAlign.start),
      AdminTableColumn(label: 'مشتری', flex: 2, align: TextAlign.start),
      AdminTableColumn(label: 'سفارش', flex: 2, align: TextAlign.start),
      AdminTableColumn(label: 'وضعیت', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'تاریخ', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'عملیات', flex: 1, align: TextAlign.center),
    ];

    final rows = filtered.asMap().entries.map((entry) {
      final index = entry.key;
      final t = entry.value;
      return [
        Text('${index + 1}', textAlign: TextAlign.center),
        Text('${t.id}', textAlign: TextAlign.center),
        Text(t.subject, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start),
        Text(t.userName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start),
        Text(t.orderNumber, textAlign: TextAlign.start, style: const TextStyle(fontSize: 12)),
        _TicketStatusChip(status: t.status),
        Text(_formatDate(t.createdAt), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        IconButton(
          tooltip: 'مشاهده تیکت',
          visualDensity: VisualDensity.compact,
          onPressed: () => context.go('/admin/tickets/${t.id}'),
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
      ];
    }).toList();

    return AdminPageScaffold(
      title: AppStrings.adminTickets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSearchBar(
            controller: _search,
            hint: 'جستجو: موضوع، مشتری، شماره سفارش، آیدی...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip('همه', 'all'),
              _statusChip('باز', 'open'),
              _statusChip('بسته', 'closed'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: _loading,
              emptyMessage: AppStrings.noTickets,
              cellPadding: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final active = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      selectedColor: AppColors.gold.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: active ? AppColors.gold : AppColors.textPrimary,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: active ? AppColors.gold : AppColors.border),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    return iso.split('T').first;
  }
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final open = status == 'open';
    final (label, color) = open ? ('باز', AppColors.success) : ('بسته', AppColors.textMuted);

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
    if (_loading) {
      return const AdminPageScaffold(
        title: AppStrings.adminTickets,
        child: AppLoadingCenter(size: 72),
      );
    }

    final ticket = _ticket;
    if (ticket == null) {
      return AdminPageScaffold(
        title: AppStrings.adminTickets,
        child: Center(child: Text(AppStrings.noTickets, style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return AdminPageScaffold(
      title: ticket.subject,
      actions: [
        if (ticket.status == 'open')
          OutlinedButton(onPressed: _close, child: const Text(AppStrings.closeTicket)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${ticket.userName} · ${ticket.orderNumber}', style: TextStyle(color: AppColors.textSecondary)),
              _TicketStatusChip(status: ticket.status),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: ticket.messages.map((m) {
                return Container(
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
                );
              }).toList(),
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(onPressed: _sendReply, child: const Text(AppStrings.send)),
            ),
          ],
        ],
      ),
    );
  }
}
