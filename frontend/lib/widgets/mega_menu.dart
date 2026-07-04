import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class MegaMenuOverlay extends StatefulWidget {
  const MegaMenuOverlay({
    super.key,
    required this.categories,
    required this.onClose,
  });

  final List<MegaMenuCategory> categories;
  final VoidCallback onClose;

  @override
  State<MegaMenuOverlay> createState() => _MegaMenuOverlayState();
}

class _MegaMenuOverlayState extends State<MegaMenuOverlay> {
  int _selectedIndex = 0;

  IconData _iconFor(String name) => switch (name) {
        'build' => Icons.build_outlined,
        'opacity' => Icons.opacity_outlined,
        'cleaning_services' => Icons.cleaning_services_outlined,
        'science' => Icons.science_outlined,
        'air' => Icons.air_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();
    final selected = widget.categories[_selectedIndex.clamp(0, widget.categories.length - 1)];
    final isMobile = AppResponsive.widthOf(context) < 900;

    return Container(
      constraints: BoxConstraints(maxHeight: isMobile ? 420 : 480),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: isMobile
          ? _MobileMenu(selected: selected, onClose: widget.onClose)
          : _DesktopMenu(
              categories: widget.categories,
              selectedIndex: _selectedIndex,
              selected: selected,
              iconFor: _iconFor,
              onSelect: (i) => setState(() => _selectedIndex = i),
              onClose: widget.onClose,
            ),
    );
  }
}

class _DesktopMenu extends StatelessWidget {
  const _DesktopMenu({
    required this.categories,
    required this.selectedIndex,
    required this.selected,
    required this.iconFor,
    required this.onSelect,
    required this.onClose,
  });

  final List<MegaMenuCategory> categories;
  final int selectedIndex;
  final MegaMenuCategory selected;
  final IconData Function(String) iconFor;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 240,
          color: AppColors.black,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final active = i == selectedIndex;
              return InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold.withValues(alpha: 0.14) : null,
                    border: Border(
                      right: BorderSide(
                        color: active ? AppColors.gold : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconFor(cat.icon),
                        size: 22,
                        color: active ? AppColors.gold : AppColors.textOnDark.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: active ? AppColors.gold : AppColors.textOnDark,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 15,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        onClose();
                        context.go('/shop?category=${Uri.encodeComponent(selected.name)}');
                      },
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: Text(AppStrings.viewAll, style: TextStyle(color: AppColors.gold)),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 32,
                      runSpacing: 24,
                      children: selected.subcategories.map((sub) {
                        return SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  onClose();
                                  context.go('/shop?part_category=${Uri.encodeComponent(sub.name)}');
                                },
                                child: Row(
                                  children: [
                                    Container(width: 3, height: 16, color: AppColors.gold),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sub.name,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_left, size: 16, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...sub.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _MegaMenuTextLink(
                                    label: item,
                                    onTap: () {
                                      onClose();
                                      context.go('/shop?search=${Uri.encodeComponent(item)}');
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({required this.selected, required this.onClose});
  final MegaMenuCategory selected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final sub in selected.subcategories) ...[
          ListTile(
            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              onClose();
              context.go('/shop?part_category=${Uri.encodeComponent(sub.name)}');
            },
          ),
          ...sub.items.map(
            (item) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
              child: _MegaMenuTextLink(
                label: item,
                onTap: () {
                  onClose();
                  context.go('/shop?search=${Uri.encodeComponent(item)}');
                },
              ),
            ),
          ),
          const Divider(),
        ],
      ],
    );
  }
}

class _MegaMenuTextLink extends StatefulWidget {
  const _MegaMenuTextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_MegaMenuTextLink> createState() => _MegaMenuTextLinkState();
}

class _MegaMenuTextLinkState extends State<_MegaMenuTextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: _hovered ? AppColors.gold : AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.normal,
              ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
