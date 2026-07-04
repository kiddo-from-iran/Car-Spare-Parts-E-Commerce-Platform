import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.widthOf(context) < 900;
    final isWide = AppResponsive.widthOf(context) >= 1200;
    final padding = AppResponsive.pagePadding(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _QuickAccessColumn(),
                SizedBox(height: 32),
                _ContactColumn(),
                SizedBox(height: 32),
                _WorkingHoursColumn(),
                SizedBox(height: 32),
                _TrustColumn(),
                SizedBox(height: 32),
                _SocialColumn(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _QuickAccessColumn()),
                const Expanded(child: _ContactColumn()),
                const Expanded(child: _WorkingHoursColumn()),
                if (isWide) const Expanded(child: _TrustColumn()),
                Expanded(child: isWide ? const _SocialColumn() : const _TrustColumn()),
                if (!isWide) const Expanded(child: _SocialColumn()),
              ],
            ),
          const SizedBox(height: 32),
          Divider(color: AppColors.border.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            AppStrings.copyright(DateTime.now().year),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessColumn extends StatelessWidget {
  const _QuickAccessColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.footerQuickAccess, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _FooterLink(label: AppStrings.footerCarCategories, onTap: () => context.go('/shop')),
        _FooterLink(label: AppStrings.footerPartCategories, onTap: () => context.go('/shop')),
        _FooterLink(label: AppStrings.shop, onTap: () => context.go('/shop')),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.footerContact, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _FooterLink(label: '${AppStrings.footerShop}: ${AppStrings.storePhone}'),
        _FooterLink(label: '${AppStrings.footerSupport}: ${AppStrings.supportPhone}'),
      ],
    );
  }
}

class _WorkingHoursColumn extends StatelessWidget {
  const _WorkingHoursColumn();

  @override
  Widget build(BuildContext context) {
    const goldStyle = TextStyle(color: AppColors.gold, fontWeight: FontWeight.w500, height: 1.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: 20, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(
              AppStrings.footerWorkingHours,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('شنبه تا چهارشنبه', style: goldStyle.copyWith(fontWeight: FontWeight.w600)),
        const Text('۸ صبح تا ۸ شب', style: goldStyle),
        const SizedBox(height: 12),
        Text('پنج‌شنبه', style: goldStyle.copyWith(fontWeight: FontWeight.w600)),
        const Text('۱۰ صبح تا ۱۴', style: goldStyle),
      ],
    );
  }
}

class _TrustColumn extends StatelessWidget {
  const _TrustColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.footerTrust, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 36, color: AppColors.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 8),
              Text('e-Namad', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialColumn extends StatelessWidget {
  const _SocialColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.footerSocial, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          children: [
            _SocialIcon(icon: Icons.camera_alt_outlined, label: 'Instagram', url: 'https://instagram.com'),
            _SocialIcon(icon: Icons.chat_outlined, label: 'WhatsApp', url: 'https://wa.me'),
            _SocialIcon(icon: Icons.send_outlined, label: 'Telegram', url: 'https://t.me/jahangiri_parts'),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  const _SocialIcon({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.label,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: _hovered ? [AppTheme.softShadow] : null,
              ),
              child: Icon(
                widget.icon,
                size: 22,
                color: _hovered ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
