import 'dart:async';

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
  bool _categoriesNavHovered = false;
  bool _megaMenuPanelHovered = false;
  List<MegaMenuCategory> _megaMenu = [];
  OverlayEntry? _megaMenuOverlay;
  Timer? _megaMenuCloseTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_megaMenu.isEmpty) _loadMegaMenu();
  }

  @override
  void dispose() {
    _megaMenuCloseTimer?.cancel();
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
    _categoriesNavHovered = false;
    _megaMenuPanelHovered = false;
    setState(() => _megaMenuOpen = false);
    _removeMegaMenuOverlay();
  }

  void _openMegaMenu() {
    _megaMenuCloseTimer?.cancel();
    if (!_megaMenuOpen) {
      setState(() => _megaMenuOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _megaMenuOpen) _showMegaMenuOverlay();
      });
    } else if (_megaMenuOverlay == null) {
      _showMegaMenuOverlay();
    }
  }

  void _onCategoriesNavEnter() {
    _categoriesNavHovered = true;
    _megaMenuCloseTimer?.cancel();
    _openMegaMenu();
  }

  void _onCategoriesNavExit() {
    _categoriesNavHovered = false;
    _scheduleCloseMegaMenuIfNeeded();
  }

  void _onMegaMenuPanelEnter() {
    _megaMenuPanelHovered = true;
    _megaMenuCloseTimer?.cancel();
    _openMegaMenu();
  }

  void _onMegaMenuPanelExit() {
    _megaMenuPanelHovered = false;
    _scheduleCloseMegaMenuIfNeeded();
  }

  void _scheduleCloseMegaMenuIfNeeded() {
    if (_categoriesNavHovered || _megaMenuPanelHovered) return;
    _scheduleCloseMegaMenu();
  }

  void _scheduleCloseMegaMenu() {
    _megaMenuCloseTimer?.cancel();
    _megaMenuCloseTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_categoriesNavHovered && !_megaMenuPanelHovered) {
        _closeMegaMenu();
      }
    });
  }

  void _cancelCloseMegaMenu() {
    _megaMenuCloseTimer?.cancel();
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
    const bridgeHeight = 20.0;

    return Stack(
      children: [
        // Dim backdrop — only below the navbar so the trigger link stays hoverable.
        Positioned(
          top: top,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeMegaMenu,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
        // Menu + invisible bridge overlapping the navbar bottom edge.
        Positioned(
          top: top - bridgeHeight,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) => _onMegaMenuPanelEnter(),
            onExit: (_) => _onMegaMenuPanelExit(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: bridgeHeight),
                Material(
                  elevation: 12,
                  color: AppColors.white,
                  child: MegaMenuOverlay(
                    categories: _megaMenu,
                    onClose: _closeMegaMenu,
                  ),
                ),
              ],
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
                  icon: Icon(_mobileMenuOpen ? Icons.close : Icons.menu, color: AppColors.black),
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
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.gold, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.brand,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                        ),
                        if (!isMobile)
                          Text(
                            AppStrings.brandTagline,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
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
                  _ActionButton(
                    icon: Icons.person_outline,
                    tooltip: AppStrings.account,
                    onTap: () {
                      _closeMegaMenu();
                      context.go('/account');
                    },
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
                  if (cart.itemCount > 0)
                    PositionedDirectional(
                      end: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textOnGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.black,
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
                    if (isMobile)
                      _NavItem(
                        label: AppStrings.categories,
                        active: _megaMenuOpen,
                        icon: Icons.menu,
                        onTap: _toggleMegaMenu,
                      )
                    else
                      _CategoriesNavItem(
                        label: AppStrings.categories,
                        active: _megaMenuOpen,
                        onOpen: _onCategoriesNavEnter,
                        onClose: _onCategoriesNavExit,
                        onCancelClose: _cancelCloseMegaMenu,
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

class _CategoriesNavItem extends StatefulWidget {
  const _CategoriesNavItem({
    required this.label,
    required this.active,
    required this.onOpen,
    required this.onClose,
    required this.onCancelClose,
  });

  final String label;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onCancelClose;

  @override
  State<_CategoriesNavItem> createState() => _CategoriesNavItemState();
}

class _CategoriesNavItemState extends State<_CategoriesNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    final textColor = highlighted ? AppColors.gold : AppColors.textOnDark.withValues(alpha: 0.85);
    final underlineColor =
        widget.active ? AppColors.gold : (_hovered ? AppColors.gold.withValues(alpha: 0.6) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onCancelClose();
        widget.onOpen();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onClose();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: underlineColor, width: 2.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, size: 18, color: textColor),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: textColor,
                    fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                  ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: _hovered ? AppColors.gold : AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: _hovered ? AppColors.gold : AppColors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _hovered;
    final textColor = highlighted ? AppColors.gold : AppColors.textOnDark.withValues(alpha: 0.85);
    final underlineColor = widget.active ? AppColors.gold : (_hovered ? AppColors.gold.withValues(alpha: 0.6) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap ??
            (widget.path != null
                ? () {
                    widget.onBeforeNavigate?.call();
                    context.go(widget.path!);
                  }
                : null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: underlineColor, width: 2.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: textColor),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: textColor,
                      fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
                    ),
                child: Text(widget.label),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 16, top: 8),
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
                  label: Text(label, style: TextStyle(color: currentPath == path ? AppColors.textOnGold : AppColors.textOnDark)),
                  backgroundColor: currentPath == path ? AppColors.gold : AppColors.blackLight,
                  side: BorderSide(color: currentPath == path ? AppColors.gold : AppColors.blackLight),
                  onPressed: () => context.go(path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
