import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Project-wide Lottie loading animation (`lib/assets/lottie/maintain.json`).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 72,
  });

  static const assetPath = 'lib/assets/lottie/maintain.json';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

/// Centered page/section loader.
class AppLoadingCenter extends StatelessWidget {
  const AppLoadingCenter({
    super.key,
    this.size = 96,
    this.padding,
  });

  final double size;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: AppLoadingIndicator(size: size),
      ),
    );
  }
}

/// Compact loader for buttons and table cells.
class AppLoadingInline extends StatelessWidget {
  const AppLoadingInline({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => AppLoadingIndicator(size: size);
}

/// Thin top-of-section fetch indicator.
class AppLoadingBar extends StatelessWidget {
  const AppLoadingBar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AppLoadingIndicator(size: size),
    );
  }
}
