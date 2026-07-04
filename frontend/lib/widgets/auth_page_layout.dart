import 'package:flutter/material.dart';

import '../theme/responsive.dart';
import 'app_surface.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 32,
        horizontal: AppResponsive.pagePadding(context),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppSurface(child: child),
        ),
      ),
    );
  }
}
