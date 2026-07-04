import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  List<Product> _products = [];
  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteProduct),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.deleteProduct)),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ApiService>().deleteProduct(product.id);
    _load();
  }

  Future<void> _showForm({Product? product}) async {
    final name = TextEditingController(text: product?.name ?? '');
    final price = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final images = TextEditingController(text: product?.images.join(', ') ?? '');
    String category = product?.category ?? (_categories.isNotEmpty ? _categories.first : '');
    bool inStock = product?.inStock ?? true;
    bool isNew = product?.isNew ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(product == null ? AppStrings.addProduct : AppStrings.editProduct),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: AppStrings.productName), textAlign: TextAlign.right),
                  TextField(controller: price, decoration: const InputDecoration(labelText: AppStrings.price), keyboardType: TextInputType.number, textAlign: TextAlign.right),
                  TextField(controller: description, decoration: const InputDecoration(labelText: AppStrings.description), maxLines: 3, textAlign: TextAlign.right),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDialogState(() => category = v ?? category),
                  ),
                  TextField(controller: images, decoration: const InputDecoration(labelText: 'URL تصاویر (با , جدا)'), textAlign: TextAlign.right),
                  SwitchListTile(
                    title: const Text(AppStrings.available),
                    value: inStock,
                    onChanged: (v) => setDialogState(() => inStock = v),
                  ),
                  SwitchListTile(
                    title: const Text(AppStrings.newBadge),
                    value: isNew,
                    onChanged: (v) => setDialogState(() => isNew = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': name.text.trim(),
                  'price': double.tryParse(price.text.trim()) ?? 0,
                  'description': description.text.trim(),
                  'category': category,
                  'colors': product?.colors ?? ['متنوع'],
                  'sizes': product?.sizes ?? ['تک سایز'],
                  'images': images.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'popularity': product?.popularity ?? 0,
                  'is_new': isNew,
                  'in_stock': inStock,
                };
                final api = context.read<ApiService>();
                if (product == null) {
                  await api.createProduct(data);
                } else {
                  await api.updateProduct(product.id, data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.adminProducts, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              ElevatedButton(onPressed: () => _showForm(), child: const Text(AppStrings.addProduct)),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            Expanded(
              child: ListView.separated(
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return ListTile(
                    tileColor: AppColors.creamLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(p.name),
                    subtitle: Text('${p.category} · ${AppStrings.formatPrice(p.price)} · ${p.inStock ? AppStrings.inStock : AppStrings.outOfStock}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showForm(product: p)),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(p)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
