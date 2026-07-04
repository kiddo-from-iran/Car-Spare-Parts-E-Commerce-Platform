import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/toast_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'live_search_bar.dart';
import 'mega_menu.dart';

class AppNavbar extends StatefulWidget {
  const AppNavbar({super.key});

  @override
  State<AppNavbar> createState() => _AppNavbarState();
}

class _AppNavbarState extends State<AppNavbar> {
  final _navKey = GlobalKey();

  bool _mobileMenuOpen = false;
  bool _megaMenuOpen = false;
  List<MegaMenuCategory> _megaMenu = [];
  OverlayEntry? _megaMenuOverlay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_megaMenu.isEmpty) _loadMegaMenu();
  }

  @override
  void dispose() {
    _removeMegaMenuOverlay();
    super.dispose();
  }

  Future<void> _loadMegaMenu() async {
    try {
      final menu = await context.read<ApiService>().getMegaMenu();
      if (mounted) setState(() => _megaMenu = menu);
    } catch (_) {}
  }

  void _onNavigate() {
    _closeMegaMenu();
    setState(() => _mobileMenuOpen = false);
  }

  void _closeMegaMenu() {
    if (!_megaMenuOpen) return;
    setState(() => _megaMenuOpen = false);
    _removeMegaMenuOverlay();
  }

  void _toggleMegaMenu() {
    if (_megaMenuOpen) {
      _closeMegaMenu();
    } else {
      setState(() => _megaMenuOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _megaMenuOpen) _showMegaMenuOverlay();
      });
    }
  }

  double _navBottomY() {
    final box = _navKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 120;
    return box.localToGlobal(Offset.zero).dy + box.size.height;
  }

  void _showMegaMenuOverlay() {
    _removeMegaMenuOverlay();
    _megaMenuOverlay = OverlayEntry(builder: _buildMegaMenuOverlay);
    Overlay.of(context).insert(_megaMenuOverlay!);
  }

  void _removeMegaMenuOverlay() {
    _megaMenuOverlay?.remove();
    _megaMenuOverlay = null;
  }

  Widget _buildMegaMenuOverlay(BuildContext context) {
    final top = _navBottomY();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeMegaMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              color: Colors.black.withValues(alpha: _megaMenuOpen ? 0.35 : 0),
            ),
          ),
        ),
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _megaMenuOpen ? 1 : 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, -12 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: Material(
              elevation: 12,
              color: AppColors.white,
              child: MegaMenuOverlay(
                categories: _megaMenu,
                onClose: _closeMegaMenu,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final isMobile = AppResponsive.widthOf(context) < 900;
    final currentPath = GoRouterState.of(context).uri.path;
    final padding = AppResponsive.pagePadding(context);

    return Column(
      key: _navKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppColors.white,
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: isMobile ? 12 : 16),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: Icon(_mobileMenuOpen ? Icons.close : Icons.menu),
                  onPressed: () => setState(() => _mobileMenuOpen = !_mobileMenuOpen),
                ),
              GestureDetector(
                onTap: () {
                  _closeMegaMenu();
                  context.go('/');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.brand,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                        ),
                        if (!isMobile)
                          Text(
                            AppStrings.brandTagline,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 32),
                Expanded(
                  child: LiveSearchBar(onNavigate: _onNavigate),
                ),
              ],
              const Spacer(),
              if (auth.isLoggedIn) ...[
                if (auth.isAdmin)
                  _ActionButton(
                    icon: Icons.dashboard_outlined,
                    tooltip: AppStrings.adminPanel,
                    onTap: () {
                      _closeMegaMenu();
                      context.go('/admin');
                    },
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: AppStrings.account,
                    child: _ActionButton(icon: Icons.person_outline, onTap: () {}),
                    onSelected: (path) {
                      _closeMegaMenu();
                      context.go(path);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: '/account/orders', child: Text(AppStrings.myOrders)),
                      const PopupMenuItem(value: '/account/profile', child: Text(AppStrings.myProfile)),
                      const PopupMenuItem(value: '/account/addresses', child: Text(AppStrings.myAddresses)),
                      const PopupMenuItem(value: '/account/wishlist', child: Text(AppStrings.myWishlist)),
                      const PopupMenuItem(value: '/account/tickets', child: Text(AppStrings.myTickets)),
                      const PopupMenuItem(value: '/account/notifications', child: Text(AppStrings.notifications)),
                    ],
                  ),
                _ActionButton(
                  icon: Icons.logout,
                  tooltip: AppStrings.logout,
                  onTap: () {
                    auth.logout();
                    context.showInfo('از حساب خارج شدید');
                  },
                ),
              ] else
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _closeMegaMenu();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(isMobile ? AppStrings.login : AppStrings.loginRegister),
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _ActionButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () {
                      _closeMegaMenu();
                      cart.toggleCart();
                    },
                  ),
                  PositionedDirectional(
                    end: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
          ),
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: isMobile && _mobileMenuOpen
              ? _MobileNav(currentPath: currentPath, onNavigate: _onNavigate)
              : Row(
                  children: [
                    _NavItem(
                      label: AppStrings.home,
                      path: '/',
                      active: currentPath == '/',
                      onBeforeNavigate: _closeMegaMenu,
                    ),
                    _NavItem(
                      label: AppStrings.categories,
                      active: _megaMenuOpen,
                      icon: Icons.menu,
                      onTap: _toggleMegaMenu,
                    ),
                    _NavItem(
                      label: AppStrings.smartCatalog,
                      path: '/smart-catalog',
                      active: currentPath.startsWith('/smart-catalog'),
                      onBeforeNavigate: _closeMegaMenu,
                    ),
                    _NavItem(
                      label: AppStrings.shop,
                      path: '/shop',
                      active: currentPath.startsWith('/shop'),
                      onBeforeNavigate: _closeMegaMenu,
                    ),
                    _NavItem(
                      label: AppStrings.contact,
                      path: '/contact',
                      active: currentPath == '/contact',
                      onBeforeNavigate: _closeMegaMenu,
                    ),
                    _NavItem(
                      label: AppStrings.about,
                      path: '/about',
                      active: currentPath == '/about',
                      onBeforeNavigate: _closeMegaMenu,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    this.path,
    this.active = false,
    this.icon,
    this.onTap,
    this.onBeforeNavigate,
  });

  final String label;
  final String? path;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          (path != null
              ? () {
                  onBeforeNavigate?.call();
                  context.go(path!);
                }
              : null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          LiveSearchBar(compact: true, onNavigate: onNavigate),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, path) in [
                (AppStrings.home, '/'),
                (AppStrings.smartCatalog, '/smart-catalog'),
                (AppStrings.shop, '/shop'),
                (AppStrings.about, '/about'),
                (AppStrings.contact, '/contact'),
              ])
                ActionChip(
                  label: Text(label),
                  onPressed: () => context.go(path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
