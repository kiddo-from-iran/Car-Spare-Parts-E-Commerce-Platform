import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({super.key});

  @override
  State<AdminRevenuePage> createState() => _AdminRevenuePageState();
}

class _AdminRevenuePageState extends State<AdminRevenuePage> {
  RevenueSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await context.read<ApiService>().getRevenueSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final summary = _summary;
    if (summary == null) return Center(child: Text(AppStrings.loadError));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.adminRevenue, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _StatCard(
                title: AppStrings.revenueTotal,
                value: AppStrings.formatPrice(summary.totalRevenue),
              ),
              _StatCard(
                title: AppStrings.orderCount,
                value: '${summary.totalOrders}',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: summary.months.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final month = summary.months[index];
                return ListTile(
                  title: Text(month.monthLabel),
                  subtitle: Text('${AppStrings.orderCount}: ${month.orderCount}'),
                  trailing: Text(
                    AppStrings.formatPrice(month.revenue),
                    style: Theme.of(context).textTheme.titleMedium,
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
