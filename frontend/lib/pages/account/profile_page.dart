import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../theme/app_theme.dart';
import 'account_addresses_section.dart';
import 'account_page_scaffold.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _name.text = user.fullName;
      _email.text = user.email ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            fullName: _name.text.trim(),
            email: _email.text.trim().isEmpty ? '' : _email.text.trim(),
          );
      if (mounted) context.showSuccess(AppStrings.toastProfileSaved);
    } catch (e) {
      if (mounted) context.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return AccountPageScaffold(
      title: AppStrings.userProfile,
      scrollable: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مشخصات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(labelText: AppStrings.phoneReadonly),
              child: Text(user.phone, textAlign: TextAlign.right),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: AppStrings.fullName),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: AppStrings.email),
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.textOnGold,
                ),
                child: Text(_saving ? AppStrings.processing : AppStrings.save),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const AccountAddressesSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
