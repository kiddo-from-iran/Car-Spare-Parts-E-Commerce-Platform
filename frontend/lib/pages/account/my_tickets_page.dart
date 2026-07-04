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
import '../../widgets/admin/admin_data_table.dart';
import 'account_page_scaffold.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  List<Order> _orders = [];
  Map<int, Ticket> _ticketByOrder = {};
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _fetching = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([api.getMyOrders(), api.getMyTickets()]);
      final orders = results[0] as List<Order>;
      final tickets = results[1] as List<Ticket>;
      if (mounted) {
        setState(() {
          _orders = orders
              .where((o) => o.status != 'delivered' && o.status != 'cancelled')
              .toList();
          _ticketByOrder = {for (final t in tickets) t.orderId: t};
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _openTicketDialog(Order order) async {
    final subject = TextEditingController();
    final message = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        final dialogWidth = width > 900 ? 560.0 : (width - 32).clamp(320.0, 560.0);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                    color: AppColors.black,
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_outlined, color: AppColors.gold, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.openTicket,
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close, color: AppColors.textOnDark),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('سفارش: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '${AppStrings.formatPrice(order.total)} · ${order.statusLabel}',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: subject,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: AppStrings.ticketSubject,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: message,
                          textAlign: TextAlign.right,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: AppStrings.ticketMessage,
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.textOnGold,
                            ),
                            child: const Text(AppStrings.send),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (submitted != true || !mounted) {
      subject.dispose();
      message.dispose();
      return;
    }

    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
      subject.dispose();
      message.dispose();
      if (mounted) context.showError('موضوع و پیام الزامی است');
      return;
    }

    try {
      final ticket = await context.read<ApiService>().createTicket(
            order.id,
            subject.text.trim(),
            message.text.trim(),
          );
      subject.dispose();
      message.dispose();
      if (!mounted) return;
      context.read<ToastProvider>().show('تیکت ثبت شد');
      await _load();
      if (!mounted) return;
      context.go('/account/tickets/${ticket.id}');
    } catch (e) {
      subject.dispose();
      message.dispose();
      if (mounted) context.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    const columns = [
      AdminTableColumn(label: 'ردیف', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'شماره سفارش', flex: 3, align: TextAlign.start),
      AdminTableColumn(label: 'تاریخ', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'مبلغ', flex: 2, align: TextAlign.start),
      AdminTableColumn(label: 'وضعیت', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'پشتیبانی', flex: 2, align: TextAlign.center),
    ];

    final rows = _orders.asMap().entries.map((entry) {
      final index = entry.key;
      final order = entry.value;
      final ticket = _ticketByOrder[order.id];

      return [
        Text('${index + 1}', textAlign: TextAlign.center),
        Text(order.orderNumber, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(_formatDate(order.createdAt), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        Text(AppStrings.formatPrice(order.total), textAlign: TextAlign.start),
        _OrderStatusChip(label: order.statusLabel, status: order.status),
        ticket != null
            ? FilledButton.tonalIcon(
                onPressed: () => context.go('/account/tickets/${ticket.id}'),
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: Text(ticket.status == 'open' ? 'مشاهده تیکت' : 'بسته شده'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              )
            : FilledButton.icon(
                onPressed: () => _openTicketDialog(order),
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: const Text(AppStrings.openTicket),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.textOnGold,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
      ];
    }).toList();

    return AccountPageScaffold(
      title: AppStrings.myTickets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تیکت پشتیبانی فقط برای سفارش‌های در جریان (تحویل‌نشده) قابل ثبت است.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          if (_fetching) ...[
            const SizedBox(height: 12),
            const AppLoadingBar(size: 28),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: false,
              emptyMessage: _fetching ? 'در حال بارگذاری...' : 'سفارش فعالی برای ثبت تیکت وجود ندارد',
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
