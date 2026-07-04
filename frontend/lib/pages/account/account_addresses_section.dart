import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/address.dart';
import '../../providers/toast_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account/address_form_dialog.dart';
import '../../widgets/app_loading_indicator.dart';

class AccountAddressesSection extends StatefulWidget {
  const AccountAddressesSection({super.key, this.compact = false});

  final bool compact;

  @override
  State<AccountAddressesSection> createState() => _AccountAddressesSectionState();
}

class _AccountAddressesSectionState extends State<AccountAddressesSection> {
  List<UserAddress> _addresses = [];
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _fetching = true);
    try {
      final list = await context.read<ApiService>().getAddresses();
      if (mounted) setState(() => _addresses = list);
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _showForm({UserAddress? existing}) async {
    final result = await showAddressFormDialog(context, existing: existing);
    if (result == null || !mounted) return;

    final data = {
      'label': result.label,
      'address': result.address,
      'latitude': result.latitude,
      'longitude': result.longitude,
      'is_default': existing?.isDefault ?? _addresses.isEmpty,
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
        content: Text('${addr.label}\n${addr.address}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.deleteAddress),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.myAddresses,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addAddress),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
              ),
            ),
          ],
        ),
        if (_fetching) ...[
          const SizedBox(height: 12),
          const AppLoadingBar(size: 28),
        ],
        const SizedBox(height: 16),
        if (!_fetching && _addresses.isEmpty)
          Text(AppStrings.noAddresses, style: TextStyle(color: AppColors.textMuted))
        else
          ..._addresses.map(
            (addr) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                  child: Icon(
                    addr.label.contains('کار') ? Icons.work_outline : Icons.home_outlined,
                    color: AppColors.gold,
                    size: 20,
                  ),
                ),
                title: Text('${addr.label}${addr.isDefault ? ' (پیش‌فرض)' : ''}'),
                subtitle: Text(addr.address, maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showForm(existing: addr),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error.withValues(alpha: 0.85)),
                      onPressed: () => _delete(addr),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
