import 'package:flutter/material.dart';

enum AppScreenSize { phone, tablet, desktop }

class AppResponsive {
  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static AppScreenSize sizeOf(BuildContext context) {
    final w = widthOf(context);
    if (w < 600) return AppScreenSize.phone;
    if (w < 1024) return AppScreenSize.tablet;
    return AppScreenSize.desktop;
  }

  static bool isPhone(BuildContext context) => sizeOf(context) == AppScreenSize.phone;
  static bool isTablet(BuildContext context) => sizeOf(context) == AppScreenSize.tablet;
  static bool isDesktop(BuildContext context) => sizeOf(context) == AppScreenSize.desktop;

  static double pagePadding(BuildContext context) {
    return switch (sizeOf(context)) {
      AppScreenSize.phone => 16,
      AppScreenSize.tablet => 28,
      AppScreenSize.desktop => 48,
    };
  }

  static int productGridColumns(BuildContext context) {
    final w = widthOf(context);
    if (w >= 1400) return 5;
    if (w >= 1100) return 4;
    if (w >= 768) return 3;
    if (w >= 480) return 2;
    return 1;
  }

  static int categoryGridColumns(BuildContext context) {
    return isPhone(context) ? 2 : isTablet(context) ? 3 : 4;
  }
}
