import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/smart_catalog.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import 'catalog_diagram.dart';
import 'catalog_product_panel.dart';

class SmartCatalogPage extends StatefulWidget {
  const SmartCatalogPage({super.key});

  @override
  State<SmartCatalogPage> createState() => _SmartCatalogPageState();
}

class _SmartCatalogPageState extends State<SmartCatalogPage> {
  List<CatalogVehicleSummary> _vehicles = [];
  CatalogVehicleDetail? _vehicle;
  List<CatalogHotspot> _hotspots = [];
  List<CatalogHotspot> _allHotspots = [];
  CatalogHotspotProduct? _product;
  List<CatalogCategory> _categories = [];

  String? _selectedVehicleId;
  String? _selectedViewId;
  String? _selectedHotspotId;
  String? _highlightHotspotId;
  String? _categoryFilter;

  bool _loadingVehicles = true;
  bool _loadingVehicle = false;
  bool _loadingHotspots = false;
  bool _loadingProduct = false;

  final _vehicleSearchCtrl = TextEditingController();
  final _partSearchCtrl = TextEditingController();
  Timer? _vehicleSearchDebounce;
  Timer? _partSearchDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _vehicleSearchDebounce?.cancel();
    _partSearchDebounce?.cancel();
    _vehicleSearchCtrl.dispose();
    _partSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final api = context.read<ApiService>();
    try {
      final results = await Future.wait([
        api.getCatalogVehicles(),
        api.getCatalogCategories(),
      ]);
      final vehicles = results[0] as List<CatalogVehicleSummary>;
      final categories = results[1] as List<CatalogCategory>;
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _categories = categories;
        _loadingVehicles = false;
      });
      if (vehicles.isNotEmpty) {
        await _selectVehicle(vehicles.first.id);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _loadVehicles({String? search}) async {
    try {
      final vehicles = await context.read<ApiService>().getCatalogVehicles(search: search);
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {}
  }

  Future<void> _selectVehicle(String id) async {
    setState(() {
      _selectedVehicleId = id;
      _loadingVehicle = true;
      _product = null;
      _selectedHotspotId = null;
      _highlightHotspotId = null;
      _categoryFilter = null;
      _partSearchCtrl.clear();
    });

    try {
      final vehicle = await context.read<ApiService>().getCatalogVehicle(id);
      if (!mounted) return;
      final viewId = vehicle.views.first.id;
      setState(() {
        _vehicle = vehicle;
        _selectedViewId = viewId;
        _loadingVehicle = false;
      });
      await _loadHotspots(viewId);
    } catch (_) {
      if (mounted) setState(() => _loadingVehicle = false);
    }
  }

  Future<void> _selectView(String viewId) async {
    if (_selectedViewId == viewId) return;
    setState(() {
      _selectedViewId = viewId;
      _selectedHotspotId = null;
      _highlightHotspotId = null;
      _product = null;
    });
    await _loadHotspots(viewId);
  }

  Future<void> _loadHotspots(String viewId) async {
    final vehicleId = _selectedVehicleId;
    if (vehicleId == null) return;

    setState(() => _loadingHotspots = true);
    try {
      final api = context.read<ApiService>();
      final all = await api.getCatalogHotspots(vehicleId, viewId);
      final filtered = _categoryFilter == null
          ? all
          : await api.getCatalogHotspots(vehicleId, viewId, category: _categoryFilter);
      if (mounted) {
        setState(() {
          _allHotspots = all;
          _hotspots = filtered;
          _loadingHotspots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHotspots = false);
    }
  }

  Future<void> _selectHotspot(CatalogHotspot hotspot, {bool mobileSheet = false}) async {
    final vehicleId = _selectedVehicleId;
    final viewId = _selectedViewId;
    if (vehicleId == null || viewId == null) return;

    setState(() {
      _selectedHotspotId = hotspot.id;
      _loadingProduct = true;
    });

    if (mobileSheet && AppResponsive.isPhone(context)) {
      // Sheet opens after product data loads.
    }

    try {
      final data = await context.read<ApiService>().getHotspotProduct(vehicleId, hotspot.id, viewId);
      if (mounted) {
        setState(() {
          _product = data;
          _loadingProduct = false;
        });
        if (mobileSheet && AppResponsive.isPhone(context)) {
          _showMobileProductSheet();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  void _showMobileProductSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.catalogDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CatalogProductPanel(
          data: _product,
          loading: _loadingProduct,
          vehicleName: _vehicle?.name ?? '',
          compact: true,
        ),
      ),
    );
  }

  Future<void> _onPartSearch(String query) async {
    _partSearchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _highlightHotspotId = null);
      return;
    }
    _partSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final vehicleId = _selectedVehicleId;
      if (vehicleId == null) return;
      try {
        final results = await context.read<ApiService>().searchCatalogHotspots(vehicleId, query);
        if (!mounted || results.isEmpty) return;
        final first = results.first;
        if (_selectedViewId != first.viewId) {
          await _selectView(first.viewId);
        }
        setState(() => _highlightHotspotId = first.hotspot.id);
        await _selectHotspot(first.hotspot);
      } catch (_) {}
    });
  }

  Future<void> _setCategory(String? categoryId) async {
    setState(() => _categoryFilter = categoryId);
    final viewId = _selectedViewId;
    if (viewId == null || _selectedVehicleId == null) return;

    if (categoryId == null) {
      await _loadHotspots(viewId);
      return;
    }

    setState(() => _loadingHotspots = true);
    try {
      final filtered = await context.read<ApiService>().getCatalogHotspots(
            _selectedVehicleId!,
            viewId,
            category: categoryId,
          );
      if (mounted) {
        setState(() {
          _hotspots = filtered;
          _loadingHotspots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHotspots = false);
    }
  }

  IconData _categoryIcon(String icon) => switch (icon) {
        'light' => Icons.lightbulb_outline,
        'bumper' => Icons.border_outer,
        'engine' => Icons.settings,
        'suspension' => Icons.height,
        'brake' => Icons.album_outlined,
        'electrical' => Icons.bolt_outlined,
        'filter' => Icons.filter_alt_outlined,
        'oil' => Icons.opacity_outlined,
        'body' => Icons.directions_car_outlined,
        'gearbox' => Icons.settings_input_component_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);
    final isPhone = AppResponsive.isPhone(context);
    final isTablet = AppResponsive.isTablet(context);
    final isDesktop = AppResponsive.isDesktop(context);

    if (_loadingVehicles) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(isPhone: isPhone),
          const SizedBox(height: 20),
          Expanded(
            child: isPhone
                ? _MobileLayout(
                    vehicles: _vehicles,
                    vehicle: _vehicle,
                    categories: _categories,
                    hotspots: _hotspots,
                    allHotspots: _allHotspots,
                    selectedVehicleId: _selectedVehicleId,
                    selectedViewId: _selectedViewId,
                    selectedHotspotId: _selectedHotspotId,
                    highlightHotspotId: _highlightHotspotId,
                    categoryFilter: _categoryFilter,
                    loadingVehicle: _loadingVehicle,
                    loadingHotspots: _loadingHotspots,
                    vehicleSearchCtrl: _vehicleSearchCtrl,
                    partSearchCtrl: _partSearchCtrl,
                    categoryIcon: _categoryIcon,
                    onVehicleSearch: (q) {
                      _vehicleSearchDebounce?.cancel();
                      _vehicleSearchDebounce = Timer(const Duration(milliseconds: 300), () => _loadVehicles(search: q));
                    },
                    onSelectVehicle: _selectVehicle,
                    onSelectView: _selectView,
                    onHotspotTap: (h) => _selectHotspot(h, mobileSheet: true),
                    onHotspotHover: (_) {},
                    onPartSearch: _onPartSearch,
                    onCategory: _setCategory,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDesktop)
                        SizedBox(
                          width: 260,
                          child: _VehicleSidebar(
                            vehicles: _vehicles,
                            selectedId: _selectedVehicleId,
                            searchCtrl: _vehicleSearchCtrl,
                            onSearch: (q) {
                              _vehicleSearchDebounce?.cancel();
                              _vehicleSearchDebounce =
                                  Timer(const Duration(milliseconds: 300), () => _loadVehicles(search: q));
                            },
                            onSelect: _selectVehicle,
                          ),
                        ),
                      if (isTablet)
                        _VehicleDrawerButton(
                          vehicles: _vehicles,
                          selectedId: _selectedVehicleId,
                          onSelect: _selectVehicle,
                        ),
                      Expanded(
                        child: _CatalogWorkspace(
                          vehicle: _vehicle,
                          categories: _categories,
                          hotspots: _hotspots,
                          allHotspots: _allHotspots,
                          selectedViewId: _selectedViewId,
                          selectedHotspotId: _selectedHotspotId,
                          highlightHotspotId: _highlightHotspotId,
                          categoryFilter: _categoryFilter,
                          loadingVehicle: _loadingVehicle,
                          loadingHotspots: _loadingHotspots,
                          partSearchCtrl: _partSearchCtrl,
                          categoryIcon: _categoryIcon,
                          onSelectView: _selectView,
                          onHotspotTap: _selectHotspot,
                          onHotspotHover: (_) {},
                          onPartSearch: _onPartSearch,
                          onCategory: _setCategory,
                        ),
                      ),
                      if (isDesktop)
                        SizedBox(
                          width: 360,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.catalogDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: CatalogProductPanel(
                              data: _product,
                              loading: _loadingProduct,
                              vehicleName: _vehicle?.name ?? '',
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isPhone});

  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.hub_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.smartCatalogTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.smartCatalogSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleSidebar extends StatelessWidget {
  const _VehicleSidebar({
    required this.vehicles,
    required this.selectedId,
    required this.searchCtrl,
    required this.onSearch,
    required this.onSelect,
  });

  final List<CatalogVehicleSummary> vehicles;
  final String? selectedId;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.directions_car_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(AppStrings.selectVehicle, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'جستجوی خودرو...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                final selected = v.id == selectedId;
                return _VehicleCard(vehicle: v, selected: selected, onTap: () => onSelect(v.id));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.selected, required this.onTap});

  final CatalogVehicleSummary vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.gold : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: vehicle.image,
                  width: 56,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 56,
                    height: 40,
                    color: AppColors.border,
                    child: const Icon(Icons.directions_car, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (vehicle.subtitle.isNotEmpty)
                      Text(vehicle.subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleDrawerButton extends StatelessWidget {
  const _VehicleDrawerButton({
    required this.vehicles,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CatalogVehicleSummary> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: IconButton.filled(
        tooltip: AppStrings.selectVehicle,
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (context) => SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(AppStrings.selectVehicle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  for (final v in vehicles)
                    ListTile(
                      leading: CachedNetworkImage(imageUrl: v.image, width: 48, height: 32, fit: BoxFit.cover),
                      title: Text(v.name),
                      subtitle: v.subtitle.isNotEmpty ? Text(v.subtitle) : null,
                      selected: v.id == selectedId,
                      onTap: () {
                        onSelect(v.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.directions_car_outlined),
      ),
    );
  }
}

class _CatalogWorkspace extends StatelessWidget {
  const _CatalogWorkspace({
    required this.vehicle,
    required this.categories,
    required this.hotspots,
    required this.allHotspots,
    required this.selectedViewId,
    required this.selectedHotspotId,
    required this.highlightHotspotId,
    required this.categoryFilter,
    required this.loadingVehicle,
    required this.loadingHotspots,
    required this.partSearchCtrl,
    required this.categoryIcon,
    required this.onSelectView,
    required this.onHotspotTap,
    required this.onHotspotHover,
    required this.onPartSearch,
    required this.onCategory,
  });

  final CatalogVehicleDetail? vehicle;
  final List<CatalogCategory> categories;
  final List<CatalogHotspot> hotspots;
  final List<CatalogHotspot> allHotspots;
  final String? selectedViewId;
  final String? selectedHotspotId;
  final String? highlightHotspotId;
  final String? categoryFilter;
  final bool loadingVehicle;
  final bool loadingHotspots;
  final TextEditingController partSearchCtrl;
  final IconData Function(String) categoryIcon;
  final ValueChanged<String> onSelectView;
  final ValueChanged<CatalogHotspot> onHotspotTap;
  final ValueChanged<CatalogHotspot?> onHotspotHover;
  final ValueChanged<String> onPartSearch;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    if (loadingVehicle || vehicle == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final v = vehicle!;
    final currentView = v.views.firstWhere((view) => view.id == selectedViewId, orElse: () => v.views.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: partSearchCtrl,
          onChanged: onPartSearch,
          decoration: InputDecoration(
            hintText: AppStrings.catalogSearchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: v.views.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final view = v.views[index];
              final active = view.id == selectedViewId;
              return ChoiceChip(
                label: Text(view.name),
                selected: active,
                onSelected: (_) => onSelectView(view.id),
                selectedColor: AppColors.gold.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(color: active ? AppColors.gold : AppColors.border),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: loadingHotspots
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
              : CatalogDiagram(
                  view: currentView,
                  hotspots: hotspots,
                  allHotspots: allHotspots,
                  selectedHotspotId: selectedHotspotId,
                  highlightedHotspotId: highlightHotspotId,
                  categoryFilter: categoryFilter,
                  onHotspotTap: onHotspotTap,
                  onHotspotHover: onHotspotHover,
                ),
        ),
        const SizedBox(height: 12),
        Text(AppStrings.catalogCategoriesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final active = categoryFilter == null;
                return _CategoryChip(
                  label: AppStrings.catalogAllCategories,
                  icon: Icons.apps,
                  active: active,
                  onTap: () => onCategory(null),
                );
              }
              final cat = categories[index - 1];
              return _CategoryChip(
                label: cat.name,
                icon: categoryIcon(cat.icon),
                active: categoryFilter == cat.id,
                onTap: () => onCategory(cat.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gold.withValues(alpha: 0.12) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.gold : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: active ? AppColors.gold : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.vehicles,
    required this.vehicle,
    required this.categories,
    required this.hotspots,
    required this.allHotspots,
    required this.selectedVehicleId,
    required this.selectedViewId,
    required this.selectedHotspotId,
    required this.highlightHotspotId,
    required this.categoryFilter,
    required this.loadingVehicle,
    required this.loadingHotspots,
    required this.vehicleSearchCtrl,
    required this.partSearchCtrl,
    required this.categoryIcon,
    required this.onVehicleSearch,
    required this.onSelectVehicle,
    required this.onSelectView,
    required this.onHotspotTap,
    required this.onHotspotHover,
    required this.onPartSearch,
    required this.onCategory,
  });

  final List<CatalogVehicleSummary> vehicles;
  final CatalogVehicleDetail? vehicle;
  final List<CatalogCategory> categories;
  final List<CatalogHotspot> hotspots;
  final List<CatalogHotspot> allHotspots;
  final String? selectedVehicleId;
  final String? selectedViewId;
  final String? selectedHotspotId;
  final String? highlightHotspotId;
  final String? categoryFilter;
  final bool loadingVehicle;
  final bool loadingHotspots;
  final TextEditingController vehicleSearchCtrl;
  final TextEditingController partSearchCtrl;
  final IconData Function(String) categoryIcon;
  final ValueChanged<String> onVehicleSearch;
  final ValueChanged<String> onSelectVehicle;
  final ValueChanged<String> onSelectView;
  final ValueChanged<CatalogHotspot> onHotspotTap;
  final ValueChanged<CatalogHotspot?> onHotspotHover;
  final ValueChanged<String> onPartSearch;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final selected = v.id == selectedVehicleId;
              return GestureDetector(
                onTap: () => onSelectVehicle(v.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.gold : AppColors.border, width: selected ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: v.image, fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _CatalogWorkspace(
            vehicle: vehicle,
            categories: categories,
            hotspots: hotspots,
            allHotspots: allHotspots,
            selectedViewId: selectedViewId,
            selectedHotspotId: selectedHotspotId,
            highlightHotspotId: highlightHotspotId,
            categoryFilter: categoryFilter,
            loadingVehicle: loadingVehicle,
            loadingHotspots: loadingHotspots,
            partSearchCtrl: partSearchCtrl,
            categoryIcon: categoryIcon,
            onSelectView: onSelectView,
            onHotspotTap: onHotspotTap,
            onHotspotHover: onHotspotHover,
            onPartSearch: onPartSearch,
            onCategory: onCategory,
          ),
        ),
      ],
    );
  }
}
