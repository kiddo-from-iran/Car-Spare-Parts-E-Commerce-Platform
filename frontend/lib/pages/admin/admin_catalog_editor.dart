import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../models/smart_catalog.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/catalog_asset_image.dart';

class _EditableHotspot {
  _EditableHotspot({
    required this.id,
    required this.label,
    required this.category,
    required this.x,
    required this.y,
    this.productIds = const [],
  });

  String id;
  String label;
  String category;
  double x;
  double y;
  List<int> productIds;

  factory _EditableHotspot.fromCatalog(CatalogHotspot h) => _EditableHotspot(
        id: h.id,
        label: h.label,
        category: h.category,
        x: h.x,
        y: h.y,
        productIds: List<int>.from(h.productIds),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category,
        'x': x,
        'y': y,
        'product_ids': productIds,
      };
}

class _EditableView {
  _EditableView({
    required this.id,
    required this.name,
    this.image = '',
    this.hotspots = const [],
  });

  String id;
  String name;
  String image;
  List<_EditableHotspot> hotspots;

  factory _EditableView.fromDetail(AdminCatalogViewDetail v) => _EditableView(
        id: v.id,
        name: v.name,
        image: v.image,
        hotspots: v.hotspots.map(_EditableHotspot.fromCatalog).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'hotspots': hotspots.map((h) => h.toJson()).toList(),
      };
}

class AdminCatalogEditor extends StatefulWidget {
  const AdminCatalogEditor({
    super.key,
    required this.detail,
    required this.products,
    required this.categories,
    required this.onSave,
    required this.onCancel,
    this.saving = false,
  });

  final AdminCatalogDetail? detail;
  final List<Product> products;
  final List<CatalogCategory> categories;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final VoidCallback onCancel;
  final bool saving;

  @override
  State<AdminCatalogEditor> createState() => _AdminCatalogEditorState();
}

class _AdminCatalogEditorState extends State<AdminCatalogEditor> {
  late final TextEditingController _name;
  late final TextEditingController _subtitle;
  late final TextEditingController _year;
  late final TextEditingController _productSearch;
  late final TextEditingController _viewNameController;
  late final TextEditingController _hotspotLabelController;
  late List<_EditableView> _views;
  late List<CatalogCategory> _categories;
  int _viewIndex = 0;
  String? _selectedHotspotId;
  bool _uploading = false;
  String _productQuery = '';

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _name = TextEditingController(text: d?.name ?? '');
    _subtitle = TextEditingController(text: d?.subtitle ?? '');
    _year = TextEditingController(text: d?.year ?? '');
    _productSearch = TextEditingController();
    _views = d != null && d.views.isNotEmpty
        ? d.views.map(_EditableView.fromDetail).toList()
        : [_EditableView(id: 'view-front', name: 'نمای جلو')];
    _categories = _initialCategories(d);
    _viewNameController = TextEditingController(text: _currentView.name);
    _hotspotLabelController = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _year.dispose();
    _productSearch.dispose();
    _viewNameController.dispose();
    _hotspotLabelController.dispose();
    super.dispose();
  }

  List<CatalogCategory> _initialCategories(AdminCatalogDetail? detail) {
    if (detail != null && detail.categories.isNotEmpty) {
      return List<CatalogCategory>.from(detail.categories);
    }
    if (widget.categories.isNotEmpty) {
      return List<CatalogCategory>.from(widget.categories);
    }
    return [
      CatalogCategory(id: 'body', name: 'بدنه', icon: 'body'),
    ];
  }

  String _defaultCategoryId() => _categories.first.id;

  String _slugCategoryId(String name) {
    var base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF_-]'), '');
    if (base.isEmpty) {
      base = 'cat-${DateTime.now().millisecondsSinceEpoch}';
    }
    if (_categories.any((c) => c.id == base)) {
      base = '$base-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    return base;
  }

  _EditableView get _currentView => _views[_viewIndex];

  Future<void> _addCategory({void Function(String id)? onCreated}) async {
    final nameController = TextEditingController();
    final created = await showDialog<CatalogCategory>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.catalogAddCategory),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: AppStrings.catalogCategoryName,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                ctx,
                CatalogCategory(id: _slugCategoryId(name), name: name, icon: 'category'),
              );
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (created == null || !mounted) return;
    setState(() => _categories = [..._categories, created]);
    onCreated?.call(created.id);
  }

  _EditableHotspot? get _selectedHotspot {
    final id = _selectedHotspotId;
    if (id == null) return null;
    for (final h in _currentView.hotspots) {
      if (h.id == id) return h;
    }
    return null;
  }

  void _selectView(int index) {
    setState(() {
      _viewIndex = index;
      _selectedHotspotId = null;
      _viewNameController.text = _currentView.name;
      _hotspotLabelController.clear();
    });
  }

  void _selectHotspot(String id) {
    final hotspot = _currentView.hotspots.firstWhere((h) => h.id == id);
    setState(() {
      _selectedHotspotId = id;
      _hotspotLabelController.text = hotspot.label;
    });
  }

  List<Product> get _filteredProducts {
    final q = _productQuery.trim().toLowerCase();
    if (q.isEmpty) return widget.products.take(20).toList();
    return widget.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.id.toString().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .take(30)
        .toList();
  }

  Future<void> _pickAndUploadImage({required bool forView}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploading = true);
    try {
      final api = context.read<ApiService>();
      final url = await api.uploadCatalogImage(bytes, file.name);
      if (!mounted) return;
      setState(() {
        if (forView) {
          _currentView.image = url;
        }
      });
      context.read<ToastProvider>().show('تصویر بارگذاری شد');
    } catch (e) {
      if (mounted) context.showError('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _addView() {
    final n = _views.length + 1;
    setState(() {
      _views.add(_EditableView(id: 'view-$n', name: 'نما $n'));
      _viewIndex = _views.length - 1;
      _selectedHotspotId = null;
    });
  }

  void _removeView(int index) {
    if (_views.length <= 1) return;
    setState(() {
      _views.removeAt(index);
      if (_viewIndex >= _views.length) _viewIndex = _views.length - 1;
      _selectedHotspotId = null;
    });
  }

  void _addHotspot(double x, double y) {
    final id = 'hs-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _currentView.hotspots = [
        ..._currentView.hotspots,
        _EditableHotspot(
          id: id,
          label: 'نقطه ${_currentView.hotspots.length + 1}',
          category: _defaultCategoryId(),
          x: x,
          y: y,
        ),
      ];
      _selectedHotspotId = id;
      _hotspotLabelController.text = 'نقطه ${_currentView.hotspots.length}';
    });
  }

  void _moveHotspot(String id, double x, double y) {
    setState(() {
      for (final h in _currentView.hotspots) {
        if (h.id == id) {
          h.x = x;
          h.y = y;
          break;
        }
      }
    });
  }

  void _removeHotspot(String id) {
    setState(() {
      _currentView.hotspots = _currentView.hotspots.where((h) => h.id != id).toList();
      if (_selectedHotspotId == id) {
        _selectedHotspotId = null;
        _hotspotLabelController.clear();
      }
    });
  }

  void _toggleProduct(int productId) {
    final hotspot = _selectedHotspot;
    if (hotspot == null) return;
    setState(() {
      if (hotspot.productIds.contains(productId)) {
        hotspot.productIds = hotspot.productIds.where((id) => id != productId).toList();
      } else {
        hotspot.productIds = [...hotspot.productIds, productId];
      }
    });
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      context.showError('نام خودرو الزامی است');
      return;
    }
    if (_views.any((v) => v.image.isEmpty)) {
      context.showError('برای هر نما تصویر بارگذاری کنید');
      return;
    }
    for (final view in _views) {
      for (final h in view.hotspots) {
        if (h.label.trim().isEmpty) {
          context.showError('عنوان همه نقاط را وارد کنید');
          return;
        }
        if (h.productIds.isEmpty) {
          context.showError('برای هر نقطه حداقل یک محصول انتخاب کنید');
          return;
        }
      }
    }

    final payload = {
      if (widget.detail != null) 'id': widget.detail!.id,
      'name': _name.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'year': _year.text.trim(),
      'brand_logo': widget.detail?.brandLogo ?? '',
      'image': _views.first.image,
      'categories': _categories
          .map((c) => {'id': c.id, 'name': c.name, 'icon': c.icon})
          .toList(),
      'views': _views.map((v) => v.toJson()).toList(),
    };
    await widget.onSave(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final selected = _selectedHotspot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('اطلاعات خودرو', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? 280 : double.infinity,
                      child: TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'نام خودرو *', border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: TextField(
                        controller: _subtitle,
                        decoration: const InputDecoration(labelText: 'زیرعنوان', border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 120 : double.infinity,
                      child: TextField(
                        controller: _year,
                        decoration: const InputDecoration(labelText: 'سال', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.catalogHotspots,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addView,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(AppStrings.catalogAddView),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_views.length, (i) {
                      final v = _views[i];
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: InputChip(
                          label: Text(v.name),
                          selected: _viewIndex == i,
                          onSelected: (_) => _selectView(i),
                          deleteIcon: _views.length > 1 ? const Icon(Icons.close, size: 16) : null,
                          onDeleted: _views.length > 1 ? () => _removeView(i) : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: isWide ? 280 : double.infinity,
                  child: TextField(
                    controller: _viewNameController,
                    decoration: const InputDecoration(
                      labelText: 'نام نما',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _currentView.name = v,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _uploading ? null : () => _pickAndUploadImage(forView: true),
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: AppLoadingInline(size: 16),
                            )
                          : const Icon(Icons.upload_file, size: 18),
                      label: const Text(AppStrings.catalogUploadImage),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.textOnGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.catalogClickToPlace,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _HotspotCanvas(
                        image: _currentView.image,
                        hotspots: _currentView.hotspots,
                        selectedId: _selectedHotspotId,
                        onTapImage: _addHotspot,
                        onSelect: _selectHotspot,
                        onMoveHotspot: _moveHotspot,
                      )),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _HotspotSidePanel(
                        hotspot: selected,
                        categories: _categories,
                        products: widget.products,
                        filteredProducts: _filteredProducts,
                        searchController: _productSearch,
                        labelController: _hotspotLabelController,
                        onSearchChanged: (v) => setState(() => _productQuery = v),
                        onLabelChanged: (v) {
                          selected?.label = v;
                        },
                        onCategoryChanged: (v) => setState(() => selected?.category = v),
                        onAddCategory: () => _addCategory(
                          onCreated: (id) => selected?.category = id,
                        ),
                        onToggleProduct: _toggleProduct,
                        onRemoveHotspot: selected == null ? null : () => _removeHotspot(selected.id),
                      )),
                    ],
                  )
                else ...[
                  _HotspotCanvas(
                    image: _currentView.image,
                    hotspots: _currentView.hotspots,
                    selectedId: _selectedHotspotId,
                    onTapImage: _addHotspot,
                    onSelect: _selectHotspot,
                    onMoveHotspot: _moveHotspot,
                  ),
                  const SizedBox(height: 16),
                  _HotspotSidePanel(
                    hotspot: selected,
                    categories: _categories,
                    products: widget.products,
                    filteredProducts: _filteredProducts,
                    searchController: _productSearch,
                    labelController: _hotspotLabelController,
                    onSearchChanged: (v) => setState(() => _productQuery = v),
                    onLabelChanged: (v) {
                      selected?.label = v;
                    },
                    onCategoryChanged: (v) => setState(() => selected?.category = v),
                    onAddCategory: () => _addCategory(
                      onCreated: (id) => selected?.category = id,
                    ),
                    onToggleProduct: _toggleProduct,
                    onRemoveHotspot: selected == null ? null : () => _removeHotspot(selected.id),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            FilledButton(
              onPressed: widget.saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: widget.saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AppLoadingInline(size: 20),
                    )
                  : const Text(AppStrings.save),
            ),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: widget.onCancel, child: const Text(AppStrings.cancel)),
          ],
        ),
      ],
    );
  }
}

class _HotspotCanvas extends StatefulWidget {
  const _HotspotCanvas({
    required this.image,
    required this.hotspots,
    required this.selectedId,
    required this.onTapImage,
    required this.onSelect,
    required this.onMoveHotspot,
  });

  final String image;
  final List<_EditableHotspot> hotspots;
  final String? selectedId;
  final void Function(double x, double y) onTapImage;
  final ValueChanged<String> onSelect;
  final void Function(String id, double x, double y) onMoveHotspot;

  @override
  State<_HotspotCanvas> createState() => _HotspotCanvasState();
}

class _HotspotCanvasState extends State<_HotspotCanvas> {
  final _canvasKey = GlobalKey();
  bool _draggingHotspot = false;

  void _updateHotspotPosition(String id, Offset globalPosition, Size canvasSize) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final x = (local.dx / canvasSize.width).clamp(0.02, 0.98);
    final y = (local.dy / canvasSize.height).clamp(0.02, 0.98);
    widget.onMoveHotspot(id, x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: widget.image.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('ابتدا تصویر نما را بارگذاری کنید', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      key: _canvasKey,
                      fit: StackFit.expand,
                      children: [
                        CatalogAssetImage(source: widget.image, fit: BoxFit.contain),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              if (_draggingHotspot) return;
                              final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final local = box.globalToLocal(details.globalPosition);
                              final x = (local.dx / canvasSize.width).clamp(0.02, 0.98);
                              final y = (local.dy / canvasSize.height).clamp(0.02, 0.98);
                              widget.onTapImage(x, y);
                            },
                          ),
                        ),
                        ...widget.hotspots.map((h) {
                          final active = widget.selectedId == h.id;
                          return Positioned(
                            left: h.x * canvasSize.width - 14,
                            top: h.y * canvasSize.height - 14,
                            child: GestureDetector(
                                onTap: () => widget.onSelect(h.id),
                                onPanStart: (_) {
                                  setState(() => _draggingHotspot = true);
                                  widget.onSelect(h.id);
                                },
                                onPanUpdate: (details) {
                                  _updateHotspotPosition(h.id, details.globalPosition, canvasSize);
                                },
                                onPanEnd: (_) {
                                  Future.microtask(() {
                                    if (mounted) setState(() => _draggingHotspot = false);
                                  });
                                },
                                onPanCancel: () {
                                  setState(() => _draggingHotspot = false);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.7),
                                      width: active ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.35),
                                        blurRadius: active ? 10 : 4,
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _HotspotSidePanel extends StatelessWidget {
  const _HotspotSidePanel({
    required this.hotspot,
    required this.categories,
    required this.products,
    required this.filteredProducts,
    required this.searchController,
    required this.labelController,
    required this.onSearchChanged,
    required this.onLabelChanged,
    required this.onCategoryChanged,
    required this.onAddCategory,
    required this.onToggleProduct,
    required this.onRemoveHotspot,
  });

  final _EditableHotspot? hotspot;
  final List<CatalogCategory> categories;
  final List<Product> products;
  final List<Product> filteredProducts;
  final TextEditingController searchController;
  final TextEditingController labelController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAddCategory;
  final ValueChanged<int> onToggleProduct;
  final VoidCallback? onRemoveHotspot;

  @override
  Widget build(BuildContext context) {
    if (hotspot == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'یک نقطه روی تصویر انتخاب کنید یا با کلیک نقطه جدید اضافه کنید',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      );
    }

    final h = hotspot!;
    final selectedProducts = products.where((p) => h.productIds.contains(p.id)).toList();
    final categoryOptions = [
      ...categories,
      if (h.category.isNotEmpty && !categories.any((c) => c.id == h.category))
        CatalogCategory(id: h.category, name: h.category, icon: 'category'),
    ];
    final selectedCategoryId = categoryOptions.any((c) => c.id == h.category)
        ? h.category
        : categoryOptions.first.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ویرایش نقطه',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onRemoveHotspot != null)
                IconButton(
                  tooltip: 'حذف نقطه',
                  onPressed: onRemoveHotspot,
                  icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.85)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: AppStrings.catalogHotspotLabel,
              border: OutlineInputBorder(),
            ),
            controller: labelController,
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCategoryId,
            decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder()),
            items: categoryOptions
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) onCategoryChanged(v);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onAddCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.catalogAddCategory),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.catalogAssignProducts, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'جستجوی محصول...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredProducts.length,
              itemBuilder: (context, i) {
                final p = filteredProducts[i];
                final selected = h.productIds.contains(p.id);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.brand} · ${AppStrings.formatPrice(p.price)}', style: const TextStyle(fontSize: 12)),
                  trailing: Icon(
                    selected ? Icons.check_circle : Icons.add_circle_outline,
                    color: selected ? AppColors.gold : AppColors.textMuted,
                  ),
                  onTap: () => onToggleProduct(p.id),
                );
              },
            ),
          ),
          if (selectedProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedProducts.map((p) {
                return InputChip(
                  label: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onDeleted: () => onToggleProduct(p.id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
