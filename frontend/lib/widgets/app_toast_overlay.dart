import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/toast_provider.dart';
import '../theme/app_theme.dart';
import 'luxury_animations.dart';

class AppToastOverlay extends StatelessWidget {
  const AppToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const _ToastStack(),
      ],
    );
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    final toasts = context.watch<ToastProvider>().toasts;
    if (toasts.isEmpty) return const SizedBox.shrink();

    final top = MediaQuery.paddingOf(context).top + 16;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final toastWidth = (screenWidth - 32).clamp(280.0, 420.0);

    return Positioned(
      top: top,
      left: 16,
      right: null,
      child: SizedBox(
        width: toastWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < toasts.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < toasts.length - 1 ? 10 : 0),
                child: _ToastCard(
                  key: ValueKey(toasts[i].id),
                  data: toasts[i],
                  onDismissed: () => context.read<ToastProvider>().dismiss(toasts[i].id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.data, required this.onDismissed});

  final ToastData data;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _progressController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: widget.data.duration,
    );
    _slide = Tween<Offset>(begin: const Offset(-1.15, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: AppCurves.luxury),
    );
    _fade = CurvedAnimation(parent: _enterController, curve: AppCurves.luxury);

    _enterController.forward();
    _progressController.forward().then((_) => _exit());
  }

  Future<void> _exit() async {
    if (_exiting || !mounted) return;
    _exiting = true;
    await _enterController.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(widget.data.type);
    final icon = _icon(widget.data.type);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
              boxShadow: [
                AppTheme.elevatedShadow,
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 18, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.data.message,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        height: 1.55,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                icon: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                onPressed: _exit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    return LinearProgressIndicator(
                      value: 1 - _progressController.value,
                      minHeight: 3,
                      backgroundColor: AppColors.creamDark,
                      color: accent.withValues(alpha: 0.85),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(ToastType type) {
    return switch (type) {
      ToastType.success => AppColors.success,
      ToastType.error => AppColors.error,
      ToastType.warning => AppColors.warning,
      ToastType.info => AppColors.gold,
    };
  }

  IconData _icon(ToastType type) {
    return switch (type) {
      ToastType.success => Icons.check_rounded,
      ToastType.error => Icons.error_outline_rounded,
      ToastType.warning => Icons.warning_amber_rounded,
      ToastType.info => Icons.info_outline_rounded,
    };
  }
}
