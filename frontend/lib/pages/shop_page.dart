import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/product_card.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    super.key,
    this.initialCategory,
    this.initialSearch,
    this.initialVehicle,
    this.initialPartCategory,
  });

  final String? initialCategory;
  final String? initialSearch;
  final String? initialVehicle;
  final String? initialPartCategory;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  static const pageSize = 20;
  static const maxPriceLimit = 40000000.0;

  String? _partCategory;
  String? _vehicle;
  String? _brand;
  String? _country;
  String? _sort;
  double _minPrice = 0;
  double _maxPrice = maxPriceLimit;
  bool _inStockOnly = false;
  bool _outOfStockOnly = false;
  String _search = '';
  int _page = 1;
  int _totalCount = 0;

  List<Product> _products = [];
  List<String> _partCategories = [];
  List<String> _vehicles = [];
  List<String> _brands = [];
  List<String> _countries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _partCategory = widget.initialPartCategory ?? widget.initialCategory;
    _vehicle = widget.initialVehicle;
    _search = widget.initialSearch ?? '';
    _loadFilters();
    _loadProducts();
  }

  Future<void> _loadFilters() async {
    final api = context.read<ApiService>();
    try {
      final vehicles = await api.getVehicleCategories();
      final parts = await api.getPartCategories();
      final brands = await api.getBrands();
      final countries = await api.getManufacturerCountries();
      if (mounted) {
        setState(() {
          _vehicles = vehicles.map((v) => v.name).toList();
          _partCategories = parts.map((p) => p.name).toList();
          _brands = brands;
          _countries = countries;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final count = await api.getProductsCount(
        partCategory: _partCategory,
        vehicle: _vehicle,
        brand: _brand,
        country: _country,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < maxPriceLimit ? _maxPrice : null,
        search: _search.isNotEmpty ? _search : null,
        inStockOnly: _inStockOnly,
        outOfStockOnly: _outOfStockOnly,
      );
      final products = await api.getProducts(
        partCategory: _partCategory,
        vehicle: _vehicle,
        brand: _brand,
        country: _country,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < maxPriceLimit ? _maxPrice : null,
        search: _search.isNotEmpty ? _search : null,
        sort: _sort,
        inStockOnly: _inStockOnly,
        outOfStockOnly: _outOfStockOnly,
        page: _page,
        pageSize: pageSize,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _totalCount = count;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _products = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages => (_totalCount / pageSize).ceil().clamp(1, 999);

  void _applyFilters() {
    _page = 1;
    _loadProducts();
  }

  void _clearFilters() {
    setState(() {
      _partCategory = null;
      _vehicle = null;
      _brand = null;
      _country = null;
      _sort = null;
      _minPrice = 0;
      _maxPrice = maxPriceLimit;
      _inStockOnly = false;
      _outOfStockOnly = false;
      _search = '';
      _page = 1;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.widthOf(context) < 1000;
    final padding = AppResponsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.shop, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(AppStrings.productCount(_totalCount), style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              SizedBox(
                width: isMobile ? 160 : 200,
                child: DropdownButtonFormField<String?>(
                  value: _sort,
                  decoration: InputDecoration(
                    labelText: AppStrings.sortBy,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('پیش‌فرض')),
                    DropdownMenuItem(value: 'newest', child: Text(AppStrings.sortNewest)),
                    DropdownMenuItem(value: 'popularity', child: Text(AppStrings.sortPopular)),
                    DropdownMenuItem(value: 'views', child: Text(AppStrings.sortViews)),
                    DropdownMenuItem(value: 'price_asc', child: Text(AppStrings.sortPriceAsc)),
                    DropdownMenuItem(value: 'price_desc', child: Text(AppStrings.sortPriceDesc)),
                    DropdownMenuItem(value: 'discount', child: Text(AppStrings.sortDiscount)),
                  ],
                  onChanged: (v) {
                    setState(() => _sort = v);
                    _loadProducts();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile)
            ExpansionTile(
              title: Text(AppStrings.filters, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [_FiltersPanel(state: this, isMobile: true)],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: _FiltersPanel(state: this, isMobile: false)),
                const SizedBox(width: 32),
                Expanded(child: _ProductArea(state: this)),
              ],
            ),
          if (isMobile) _ProductArea(state: this),
        ],
      ),
    );
  }
}

class _ProductArea extends StatelessWidget {
  const _ProductArea({required this.state});
  final _ShopPageState state;

  @override
  Widget build(BuildContext context) {
    if (state._loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (state._products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Text(AppStrings.noProducts, style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 16),
        ProductGrid(products: state._products),
        const SizedBox(height: 32),
        _Pagination(state: state),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.state});
  final _ShopPageState state;

  @override
  Widget build(BuildContext context) {
    if (state._totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state._page > 1
              ? () {
                  state.setState(() => state._page--);
                  state._loadProducts();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
        ...List.generate(state._totalPages.clamp(0, 7), (i) {
          final page = i + 1;
          final active = page == state._page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: active ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  state.setState(() => state._page = page);
                  state._loadProducts();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: active ? AppColors.primary : AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: state._page < state._totalPages
              ? () {
                  state.setState(() => state._page++);
                  state._loadProducts();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({required this.state, required this.isMobile});
  final _ShopPageState state;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.filters, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _FilterSection(
            title: AppStrings.vehicleFilter,
            children: state._vehicles.map((v) => _CheckTile(
                  label: v,
                  value: state._vehicle == v,
                  onChanged: (checked) => state.setState(() => state._vehicle = checked ? v : null),
                )).toList(),
          ),
          _FilterSection(
            title: AppStrings.partCategoryFilter,
            children: state._partCategories.map((c) => _CheckTile(
                  label: c,
                  value: state._partCategory == c,
                  onChanged: (checked) => state.setState(() => state._partCategory = checked ? c : null),
                )).toList(),
          ),
          _FilterSection(
            title: AppStrings.countryFilter,
            children: state._countries.map((c) => _CheckTile(
                  label: c,
                  value: state._country == c,
                  onChanged: (checked) => state.setState(() => state._country = checked ? c : null),
                )).toList(),
          ),
          _FilterSection(
            title: AppStrings.brandFilter,
            children: state._brands.map((b) => _CheckTile(
                  label: b,
                  value: state._brand == b,
                  onChanged: (checked) => state.setState(() => state._brand = checked ? b : null),
                )).toList(),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.formatPriceRange(state._minPrice, state._maxPrice),
              style: Theme.of(context).textTheme.labelMedium),
          RangeSlider(
            values: RangeValues(state._minPrice, state._maxPrice),
            min: 0,
            max: _ShopPageState.maxPriceLimit,
            divisions: 40,
            onChanged: (v) => state.setState(() {
              state._minPrice = v.start;
              state._maxPrice = v.end;
            }),
          ),
          _FilterSection(
            title: AppStrings.availability,
            children: [
              _CheckTile(
                label: AppStrings.available,
                value: state._inStockOnly,
                onChanged: (v) => state.setState(() {
                  state._inStockOnly = v;
                  if (v) state._outOfStockOnly = false;
                }),
              ),
              _CheckTile(
                label: AppStrings.unavailable,
                value: state._outOfStockOnly,
                onChanged: (v) => state.setState(() {
                  state._outOfStockOnly = v;
                  if (v) state._inStockOnly = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: state._applyFilters, child: const Text(AppStrings.applyFilters)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: state._clearFilters, child: const Text(AppStrings.clearAll)),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
