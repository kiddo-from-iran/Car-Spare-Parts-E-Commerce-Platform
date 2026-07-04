import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../models/search_suggestion.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/category_carousel.dart';
import '../widgets/feature_cards.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/partner_brands.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CategoryItem> _vehicles = [];
  List<CategoryItem> _parts = [];
  List<PartnerBrand> _brands = [];
  List<dynamic> _featured = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    try {
      final results = await Future.wait([
        api.getVehicleCategories(),
        api.getPartCategories(),
        api.getPartnerBrands(),
        api.getProducts(featured: true),
      ]);
      if (mounted) {
        setState(() {
          _vehicles = results[0] as List<CategoryItem>;
          _parts = results[1] as List<CategoryItem>;
          _brands = results[2] as List<PartnerBrand>;
          _featured = results[3] as List;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeroCarousel(),
        const SizedBox(height: 48),
        if (_vehicles.isNotEmpty)
          CategoryCarousel(
            title: AppStrings.carCategoriesTitle,
            items: _vehicles,
            queryKey: 'vehicle',
            visibleItems: 5,
            largeItems: true,
          ),
        const SizedBox(height: 48),
        if (_parts.isNotEmpty)
          CategoryCarousel(
            title: AppStrings.partCategoriesTitle,
            items: _parts,
            queryKey: 'part_category',
            visibleItems: 8,
            largeItems: false,
          ),
        PartnerBrandsSection(brands: _brands),
        const FeatureCards(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'محصولات پرفروش',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'قطعات یدکی با بیشترین فروش',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_featured.isEmpty)
                Text(AppStrings.loadError, style: TextStyle(color: AppColors.textMuted))
              else
                ProductGrid(products: _featured.cast(), animate: true),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}
