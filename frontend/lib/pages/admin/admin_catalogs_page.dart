import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../models/smart_catalog.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_data_table.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_catalog_editor.dart';

class AdminCatalogsPage extends StatefulWidget {
  const AdminCatalogsPage({super.key});

  @override
  State<AdminCatalogsPage> createState() => _AdminCatalogsPageState();
}

class _AdminCatalogsPageState extends State<AdminCatalogsPage> {
  List<AdminCatalogSummary> _catalogs = [];
  bool _loading = true;
  bool _saving = false;
  AdminCatalogDetail? _editing;
  bool _isNew = false;
  List<Product> _products = [];
  List<CatalogCategory> _categories = [];
  final _search = TextEditingController();
  String _query = '';

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
      final results = await Future.wait([
        api.getAdminCatalogs(),
        api.getAdminProducts(),
        api.getCatalogCategories(),
      ]);
      if (mounted) {
        setState(() {
          _catalogs = results[0] as List<AdminCatalogSummary>;
          _products = results[1] as List<Product>;
          _categories = results[2] as List<CatalogCategory>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDetail(String id) async {
    setState(() => _loading = true);
    try {
      final detail = await context.read<ApiService>().getAdminCatalog(id);
      if (mounted) {
        setState(() {
          _editing = detail;
          _isNew = false;
        });
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<AdminCatalogSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _catalogs;
    return _catalogs
        .where((c) => c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _delete(AdminCatalogSummary catalog) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کاتالوگ'),
        content: Text('آیا از حذف «${catalog.name}» مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ApiService>().deleteAdminCatalog(catalog.id);
      if (mounted) {
        context.read<ToastProvider>().show('حذف شد');
        await _load();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  Future<void> _save(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      await api.saveAdminCatalog(data, id: _isNew ? null : _editing?.id);
      if (mounted) {
        context.read<ToastProvider>().show('ذخیره شد');
        setState(() {
          _editing = null;
          _isNew = false;
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
    if (_editing != null || _isNew) {
      return AdminPageScaffold(
        title: _isNew ? AppStrings.addCatalog : AppStrings.editCatalog,
        scrollable: true,
        child: AdminCatalogEditor(
          detail: _editing,
          products: _products,
          categories: _categories.isNotEmpty
              ? _categories
              : [
                  CatalogCategory(id: 'body', name: 'بدنه', icon: 'directions_car'),
                  CatalogCategory(id: 'engine', name: 'موتور', icon: 'settings'),
                  CatalogCategory(id: 'electrical', name: 'برقی', icon: 'bolt'),
                ],
          saving: _saving,
          onCancel: () => setState(() {
            _editing = null;
            _isNew = false;
          }),
          onSave: _save,
        ),
      );
    }

    final filtered = _filtered;
    final columns = const [
      AdminTableColumn(label: 'ردیف', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'نام خودرو', flex: 4, align: TextAlign.start),
      AdminTableColumn(label: 'نماها', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'نقاط', flex: 1, align: TextAlign.center),
      AdminTableColumn(label: 'عملیات', flex: 1, align: TextAlign.center),
    ];

    final rows = filtered.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      return [
        Text('${index + 1}', textAlign: TextAlign.center),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (c.subtitle.isNotEmpty)
              Text(
                c.subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        Text('${c.viewCount}', textAlign: TextAlign.center),
        Text('${c.hotspotCount}', textAlign: TextAlign.center),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: AppStrings.editCatalog,
              visualDensity: VisualDensity.compact,
              onPressed: () => _loadDetail(c.id),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'حذف',
              visualDensity: VisualDensity.compact,
              onPressed: () => _delete(c),
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ];
    }).toList();

    return AdminPageScaffold(
      title: AppStrings.adminCatalogs,
      actions: [
        FilledButton.icon(
          onPressed: () => setState(() {
            _isNew = true;
            _editing = null;
          }),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addCatalog),
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.textOnGold),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSearchBar(
            controller: _search,
            hint: 'جستجو بر اساس نام خودرو...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminDataTable(
              columns: columns,
              rows: rows,
              loading: _loading,
              emptyMessage: 'کاتالوگی ثبت نشده است',
            ),
          ),
        ],
      ),
    );
  }
}
