import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/address.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<UserAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<ApiService>().getAddresses();
      if (mounted) setState(() => _addresses = list);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showForm({UserAddress? existing}) async {
    final label = TextEditingController(text: existing?.label ?? 'خانه');
    final firstName = TextEditingController(text: existing?.firstName ?? '');
    final lastName = TextEditingController(text: existing?.lastName ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final state = TextEditingController(text: existing?.state ?? '');
    final zip = TextEditingController(text: existing?.zipCode ?? '');
    final country = TextEditingController(text: existing?.country ?? 'ایران');
    var isDefault = existing?.isDefault ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? AppStrings.addAddress : AppStrings.editAddress),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: label, decoration: const InputDecoration(labelText: AppStrings.addressLabel)),
                TextField(controller: firstName, decoration: const InputDecoration(labelText: AppStrings.firstName)),
                TextField(controller: lastName, decoration: const InputDecoration(labelText: AppStrings.lastName)),
                TextField(controller: address, decoration: const InputDecoration(labelText: AppStrings.address)),
                TextField(controller: city, decoration: const InputDecoration(labelText: AppStrings.city)),
                TextField(controller: state, decoration: const InputDecoration(labelText: AppStrings.state)),
                TextField(controller: zip, decoration: const InputDecoration(labelText: AppStrings.zipCode)),
                TextField(controller: country, decoration: const InputDecoration(labelText: AppStrings.country)),
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v ?? false),
                  title: const Text(AppStrings.defaultAddress),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.save)),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final data = {
      'label': label.text.trim(),
      'first_name': firstName.text.trim(),
      'last_name': lastName.text.trim(),
      'address': address.text.trim(),
      'city': city.text.trim(),
      'state': state.text.trim(),
      'zip_code': zip.text.trim(),
      'country': country.text.trim(),
      'is_default': isDefault,
    };

    try {
      if (existing == null) {
        await context.read<ApiService>().createAddress(data);
        if (mounted) context.showSuccess(AppStrings.toastAddressSaved);
      } else {
        await context.read<ApiService>().updateAddress(existing.id, data);
        if (mounted) context.showSuccess(AppStrings.toastAddressSaved);
      }
      await _load();
    } catch (e) {
      if (mounted) context.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(UserAddress addr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteAddress),
        content: Text(addr.summary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.deleteAddress)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ApiService>().deleteAddress(addr.id);
      if (mounted) context.showInfo(AppStrings.toastAddressDeleted);
      await _load();
    } catch (e) {
      if (mounted) context.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return Padding(
      padding: EdgeInsets.all(AppResponsive.pagePadding(context)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(AppStrings.myAddresses, style: Theme.of(context).textTheme.headlineMedium),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addAddress),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_addresses.isEmpty)
              Text(AppStrings.noAddresses, style: Theme.of(context).textTheme.bodyLarge)
            else
              ..._addresses.map(
                (addr) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('${addr.label}${addr.isDefault ? ' (پیش‌فرض)' : ''}'),
                    subtitle: Text('${addr.fullName}\n${addr.summary}\n${addr.zipCode}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showForm(existing: addr),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.textMuted),
                          onPressed: () => _delete(addr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
