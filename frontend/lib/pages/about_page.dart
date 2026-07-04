import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_assets.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/luxury_animations.dart';
import '../widgets/map_embed.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static final _mapsUrl = Uri.parse('https://maps.google.com/?q=Baghestan,Karaj,Iran');

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);
    final isMobile = AppResponsive.isPhone(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          FadeSlideIn(
            child: Text(
              AppStrings.aboutTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 32),
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 2, child: _AboutContent()),
                const SizedBox(width: 48),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.aboutUs,
                      height: 360,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 360,
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.storefront_outlined, size: 64, color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                AppAssets.aboutUs,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.storefront_outlined, size: 48, color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _AboutContent(),
          ],
          const SizedBox(height: 48),
          Text('موقعیت ما', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(AppStrings.aboutAddress, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => launchUrl(_mapsUrl, mode: LaunchMode.externalApplication),
            borderRadius: BorderRadius.circular(16),
            child: MapEmbed(height: isMobile ? 200 : 320),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppStrings.aboutManagement,
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.aboutHistory,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.9),
        ),
        const SizedBox(height: 24),
        _ValueItem(icon: Icons.history, text: 'بیش از ۵۰ سال سابقه فعالیت در زمینه فروش قطعات یدکی خودرو'),
        _ValueItem(icon: Icons.verified, text: 'تعهد به فروش محصولات اصل و دارای گارانتی'),
        _ValueItem(icon: Icons.support_agent, text: 'مشاوره فنی حرفه‌ای توسط کارشناسان مجرب'),
        _ValueItem(icon: Icons.thumb_up_outlined, text: 'رضایت مشتری در اولویت اول فعالیت ما'),
      ],
    );
  }
}

class _ValueItem extends StatelessWidget {
  const _ValueItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6))),
        ],
      ),
    );
  }
}
