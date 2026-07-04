import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../theme/responsive.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;
  String? _error;

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
    setState(() {
      _saving = true;
      _error = null;
    });
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

    return Padding(
      padding: EdgeInsets.all(AppResponsive.pagePadding(context)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.myProfile, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? AppStrings.processing : AppStrings.save),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/account/addresses'),
              child: const Text(AppStrings.myAddresses),
            ),
          ],
        ),
      ),
    );
  }
}
