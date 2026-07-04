import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/luxury_animations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                Expanded(
                  flex: 2,
                  child: _AboutContent(),
                ),
                const SizedBox(width: 48),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: 'https://picsum.photos/seed/jahangiri-store/800/600',
                      height: 360,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: 'https://picsum.photos/seed/jahangiri-store/800/400',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
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
            onTap: () => launchUrl(
              Uri.parse('https://maps.google.com/?q=Baghestan,Karaj,Iran'),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: isMobile ? 200 : 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text('باغستان، کرج — کلیک برای مشاهده در نقشه',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
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
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppStrings.aboutManagement,
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
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
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6))),
        ],
      ),
    );
  }
}
