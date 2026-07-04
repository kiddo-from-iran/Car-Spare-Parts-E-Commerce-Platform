import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'catalog_asset_image.dart';
import 'luxury_animations.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_current + 1) % AppStrings.heroSlides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: AppCurves.luxury,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _slideImage(int index) {
    if (index < AppAssets.slideshow.length) {
      return AppAssets.slideshow[index];
    }
    return AppAssets.slideshow.first;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = AppResponsive.isPhone(context);
    final height = isPhone ? 280.0 : AppResponsive.isTablet(context) ? 380.0 : 480.0;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: AppStrings.heroSlides.length,
            itemBuilder: (context, index) {
              final (title, subtitle, _) = AppStrings.heroSlides[index];
              final image = _slideImage(index);
              return Stack(
                fit: StackFit.expand,
                children: [
                  _SlideImage(path: image),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [
                          AppColors.black.withValues(alpha: 0.82),
                          AppColors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isPhone ? 24 : 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeSlideIn(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isPhone ? 24 : null,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: isPhone ? double.infinity : 480,
                          child: Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.7,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/shop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.textOnGold,
                            elevation: 2,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                          child: const Text(AppStrings.exploreShop),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AppStrings.heroSlides.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : AppColors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          if (!isPhone) ...[
            PositionedDirectional(
              start: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_left,
                  onTap: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: AppCurves.luxury,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ArrowButton(
                  icon: Icons.chevron_right,
                  onTap: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: AppCurves.luxury,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideImage extends StatelessWidget {
  const _SlideImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return CatalogAssetImage(
      source: path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
