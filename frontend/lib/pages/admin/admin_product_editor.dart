import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminProductEditor extends StatefulWidget {
  const AdminProductEditor({
    super.key,
    required this.product,
    required this.categories,
    required this.onSave,
    required this.onCancel,
    this.saving = false,
  });

  final Product? product;
  final List<String> categories;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final VoidCallback onCancel;
  final bool saving;

  @override
  State<AdminProductEditor> createState() => _AdminProductEditorState();
}

class _AdminProductEditorState extends State<AdminProductEditor> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _originalPrice;
  late final TextEditingController _discount;
  late final TextEditingController _description;
  late final TextEditingController _brand;
  late final TextEditingController _partCategory;
  late final TextEditingController _stock;
  late final TextEditingController _newImageUrl;
  late List<String> _images;
  late String _category;
  late bool _inStock;
  late bool _isNew;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _originalPrice = TextEditingController(text: p?.originalPrice.toStringAsFixed(0) ?? '');
    _discount = TextEditingController(text: p?.discountPercent.toStringAsFixed(0) ?? '0');
    _description = TextEditingController(text: p?.description ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _partCategory = TextEditingController(text: p?.partCategory ?? '');
    _stock = TextEditingController(text: '${p?.stockQuantity ?? 0}');
    _newImageUrl = TextEditingController();
    _images = List<String>.from(p?.images ?? []);
    _category = p?.category ?? (widget.categories.isNotEmpty ? widget.categories.first : '');
    _inStock = p?.inStock ?? true;
    _isNew = p?.isNew ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _originalPrice.dispose();
    _discount.dispose();
    _description.dispose();
    _brand.dispose();
    _partCategory.dispose();
    _stock.dispose();
    _newImageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = {
      'name': _name.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'original_price': double.tryParse(_originalPrice.text.trim()) ?? double.tryParse(_price.text.trim()) ?? 0,
      'discount_percent': double.tryParse(_discount.text.trim()) ?? 0,
      'description': _description.text.trim(),
      'category': _category,
      'part_category': _partCategory.text.trim(),
      'brand': _brand.text.trim(),
      'colors': widget.product?.colors ?? ['متنوع'],
      'sizes': widget.product?.sizes ?? ['تک سایز'],
      'images': _images,
      'popularity': widget.product?.popularity ?? 0,
      'stock_quantity': int.tryParse(_stock.text.trim()) ?? 0,
      'is_new': _isNew,
      'in_stock': _inStock,
    };
    await widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.arrow_forward)),
              Text(
                widget.product == null ? AppStrings.addProduct : AppStrings.editProduct,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              OutlinedButton(onPressed: widget.saving ? null : widget.onCancel, child: const Text(AppStrings.cancel)),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textOnGold),
                child: widget.saving
                    ? const AppLoadingInline(size: 18)
                    : const Text(AppStrings.save),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: wide ? 2 : 0,
                    child: _Section(
                      title: 'تصاویر محصول',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_images.isEmpty)
                            Container(
                              height: 160,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text('بدون تصویر', style: TextStyle(color: AppColors.textMuted)),
                            )
                          else
                            SizedBox(
                              height: 160,
                              child: ReorderableListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (newIndex > oldIndex) newIndex--;
                                    final item = _images.removeAt(oldIndex);
                                    _images.insert(newIndex, item);
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final url = _images[index];
                                  return SizedBox(
                                    key: ValueKey(url),
                                    width: 140,
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional.only(end: 12),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: CachedNetworkImage(
                                              imageUrl: url,
                                              width: 128,
                                              height: 128,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => ColoredBox(
                                                color: AppColors.surfaceMuted,
                                                child: const Icon(Icons.broken_image_outlined),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          left: 16,
                                          child: IconButton.filled(
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black54,
                                              minimumSize: const Size(28, 28),
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () => setState(() => _images.removeAt(index)),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newImageUrl,
                                  decoration: const InputDecoration(
                                    labelText: 'URL تصویر جدید',
                                    isDense: true,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final url = _newImageUrl.text.trim();
                                  if (url.isEmpty) return;
                                  setState(() {
                                    _images.add(url);
                                    _newImageUrl.clear();
                                  });
                                },
                                child: const Text('افزودن'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (wide) const SizedBox(width: 24) else const SizedBox(height: 24),
                  Expanded(
                    flex: wide ? 3 : 0,
                    child: _Section(
                      title: 'مشخصات محصول',
                      child: Column(
                        children: [
                          _field(_name, AppStrings.productName),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _field(_price, AppStrings.price, keyboard: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_originalPrice, 'قیمت اصلی', keyboard: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_discount, AppStrings.discount, keyboard: TextInputType.number)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _category.isEmpty ? null : _category,
                            decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                            items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _category = v ?? _category),
                          ),
                          const SizedBox(height: 12),
                          _field(_partCategory, 'دسته قطعه'),
                          const SizedBox(height: 12),
                          _field(_brand, AppStrings.productBrand),
                          const SizedBox(height: 12),
                          _field(_stock, 'موجودی', keyboard: TextInputType.number),
                          const SizedBox(height: 12),
                          _field(_description, AppStrings.description, maxLines: 4),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text(AppStrings.available),
                            value: _inStock,
                            onChanged: (v) => setState(() => _inStock = v),
                          ),
                          SwitchListTile(
                            title: const Text(AppStrings.newBadge),
                            value: _isNew,
                            onChanged: (v) => setState(() => _isNew = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: keyboard,
      maxLines: maxLines,
      textAlign: TextAlign.right,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
