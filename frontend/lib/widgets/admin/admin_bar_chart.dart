import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    this.valueFormatter,
    this.barColor = AppColors.gold,
  });

  final List<String> labels;
  final List<double> values;
  final String title;
  final String Function(double)? valueFormatter;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _ChartCard(
        title: title,
        child: Center(child: Text('داده‌ای موجود نیست', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: title,
      child: SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (valueFormatter != null)
                        Text(
                          valueFormatter!(values[i]),
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: maxVal > 0 ? (values[i] / maxVal) * 140 : 0,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
