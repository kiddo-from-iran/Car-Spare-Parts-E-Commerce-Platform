import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'cart_sidebar.dart';
import 'footer.dart';
import 'luxury_animations.dart';
import 'navbar.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.child,
    this.showFooter = true,
    this.scrollWithFooter = true,
    this.scrollBody = true,
  });

  final Widget child;
  final bool showFooter;
  final bool scrollWithFooter;
  final bool scrollBody;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppNavbar(),
              Expanded(
                child: scrollBody && scrollWithFooter && showFooter
                    ? CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(child: child),
                          if (showFooter) const SliverToBoxAdapter(child: AppFooter()),
                        ],
                      )
                    : scrollBody
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                child,
                                if (showFooter && scrollWithFooter) const AppFooter(),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(child: child),
                              if (showFooter) const AppFooter(),
                            ],
                          ),
              ),
            ],
          ),
          if (cart.isOpen) ...[
            GestureDetector(
              onTap: cart.closeCart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: AppCurves.luxury,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 320),
              curve: AppCurves.luxury,
              offset: cart.isOpen ? Offset.zero : const Offset(1, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CartSidebar(fullScreen: isMobile),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final isAdmin = path.startsWith('/admin');
    final isAccount = path.startsWith('/account');

    return MainLayout(
      showFooter: !isAdmin && !isAccount,
      scrollWithFooter: !isAdmin && !isAccount,
      scrollBody: !isAdmin && !isAccount,
      child: LuxuryPageTransition(child: child),
    );
  }
}
