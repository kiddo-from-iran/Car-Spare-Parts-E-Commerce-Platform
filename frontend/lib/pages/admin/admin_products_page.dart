import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_product_editor.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  List<Product> _products = [];
  List<String> _categories = [];
  bool _loading = true;
  bool _saving = false;
  Product? _editing;
  bool _isNewProduct = false;
  final _search = TextEditingController();
  String _query = '';
  final Set<int> _updatingStock = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([api.getAdminProducts(), api.getCategories()]);
      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _categories = results[1] as List<String>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) || p.id.toString().contains(q);
    }).toList();
  }

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteProduct),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.deleteProduct),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ApiService>().deleteProduct(product.id);
    if (mounted) context.read<ToastProvider>().show('محصول حذف شد');
    _load();
  }

  Future<void> _updateStock(Product product, int qty) async {
    setState(() => _updatingStock.add(product.id));
    try {
      await context.read<ApiService>().updateProduct(product.id, {
        'stock_quantity': qty,
        'in_stock': qty > 0,
      });
      if (mounted) {
        setState(() {
          final i = _products.indexWhere((p) => p.id == product.id);
          if (i >= 0) {
            _products[i] = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              originalPrice: product.originalPrice,
              discountPercent: product.discountPercent,
              description: product.description,
              category: product.category,
              partCategory: product.partCategory,
              brand: product.brand,
              manufacturerCountry: product.manufacturerCountry,
              compatibleVehicles: product.compatibleVehicles,
              colors: product.colors,
              sizes: product.sizes,
              images: product.images,
              specs: product.specs,
              popularity: product.popularity,
              views: product.views,
              rating: product.rating,
              reviewCount: product.reviewCount,
              stockQuantity: qty,
              createdAt: product.createdAt,
              isNew: product.isNew,
              inStock: qty > 0,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    } finally {
      if (mounted) setState(() => _updatingStock.remove(product.id));
    }
  }

  Future<void> _saveProduct(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      if (_isNewProduct) {
        await api.createProduct(data);
      } else {
        await api.updateProduct(_editing!.id, data);
      }
      if (mounted) {
        context.read<ToastProvider>().show('ذخیره شد');
        setState(() {
          _editing = null;
          _isNewProduct = false;
        });
        await _load();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing != null || _isNewProduct) {
      return AdminPageScaffold(
        title: AppStrings.adminProducts,
        scrollable: true,
        child: AdminProductEditor(
          product: _editing,
          categories: _categories,
          saving: _saving,
          onCancel: () => setState(() {
            _editing = null;
            _isNewProduct = false;
          }),
          onSave: _saveProduct,
        ),
      );
    }

    final filtered = _filtered;
    final columns = const [
      AdminTableColumn(label: 'ردیف', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'آیدی', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'نام محصول', flex: 4, align: TextAlign.start),
      AdminTableColumn(label: 'قیمت', flex: 2, align: TextAlign.start),
      AdminTableColumn(label: 'وضعیت', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'تعداد', flex: 2, align: TextAlign.center),
      AdminTableColumn(label: 'عملیات', flex: 1, align: TextAlign.center),
    ];

    final rows = filtered.asMap().entries.map((entry) {
      final index = entry.key;
      final p = entry.value;
      return [
        Text('${index + 1}', textAlign: TextAlign.center),
        Text('${p.id}', textAlign: TextAlign.center),
        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start),
        Text(AppStrings.formatPrice(p.price), textAlign: TextAlign.start),
        _StatusChip(inStock: p.inStock, stock: p.stockQuantity),
        AdminQuantityStepper(
          value: p.stockQuantity,
          loading: _updatingStock.contains(p.id),
          onChanged: (v) => _updateStock(p, v),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'ویرایش مشخصات',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _editing = p),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: AppStrings.deleteProduct,
              visualDensity: VisualDensity.compact,
              onPressed: () => _delete(p),
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ];
    }).toList();

    return AdminPageScaffold(
      title: AppStrings.adminProducts,
      actions: [
        FilledButton.icon(
          onPressed: () => setState(() {
            _isNewProduct = true;
            _editing = null;
          }),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addProduct),
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textOnGold),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSearchBar(
            controller: _search,
            hint: 'جستجو بر اساس نام یا آیدی محصول...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: _loading,
              emptyMessage: AppStrings.noProducts,
              cellPadding: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.inStock, required this.stock});

  final bool inStock;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final (label, color) = !inStock || stock == 0
        ? (AppStrings.outOfStock, AppColors.error)
        : stock <= 5
            ? ('موجودی کم', AppColors.warning)
            : (AppStrings.inStock, AppColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
