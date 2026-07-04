import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/toast_provider.dart';
import '../../widgets/auth_page_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_phone.text.trim(), _password.text);
      if (!mounted) return;
      context.showSuccess(AppStrings.toastLoginSuccess);
      final auth = context.read<AuthProvider>();
      context.go(auth.isAdmin ? '/admin/orders' : '/account/orders');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      context.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.login, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: AppStrings.phone),
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: AppStrings.password),
            obscureText: true,
            textAlign: TextAlign.right,
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text(AppStrings.forgotPassword),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? AppStrings.processing : AppStrings.login),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/register'),
            child: Text('${AppStrings.noAccount} ${AppStrings.register}'),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _verifiedPhone;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = await context.read<AuthProvider>().registerSendOtp(
            phone: _phone.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          );
      setState(() {
        _otpSent = true;
        _verifiedPhone = phone;
      });
      if (mounted) context.showInfo('${AppStrings.toastOtpSent} — ${AppStrings.otpHint}');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) context.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().registerVerify(
            _verifiedPhone ?? _phone.text.trim(),
            _otp.text.trim(),
          );
      if (!mounted) return;
      context.showSuccess(AppStrings.toastRegisterSuccess);
      context.go('/account/orders');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) context.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.register, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          if (!_otpSent) ...[
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: AppStrings.fullName),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: AppStrings.phone),
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: AppStrings.email),
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: AppStrings.password),
              obscureText: true,
              textAlign: TextAlign.right,
            ),
          ] else ...[
            Text(
              '${AppStrings.otpCode} — $_verifiedPhone',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.otpHint,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              decoration: const InputDecoration(labelText: AppStrings.otpCode),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : (_otpSent ? _verify : _sendOtp),
            child: Text(
              _loading
                  ? AppStrings.processing
                  : (_otpSent ? AppStrings.verifyOtp : AppStrings.sendOtp),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('${AppStrings.haveAccount} ${AppStrings.login}'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _verifiedPhone;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = await context.read<AuthProvider>().forgotPasswordSendOtp(_phone.text.trim());
      setState(() {
        _otpSent = true;
        _verifiedPhone = phone;
      });
      if (mounted) context.showInfo('${AppStrings.toastOtpSent} — ${AppStrings.otpHint}');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) context.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().resetPassword(
            _verifiedPhone ?? _phone.text.trim(),
            _otp.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      context.showSuccess(AppStrings.toastPasswordChanged);
      context.go('/login');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) context.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.forgotPassword, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          if (!_otpSent) ...[
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: AppStrings.phone),
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
            ),
          ] else ...[
            TextField(
              controller: _otp,
              decoration: const InputDecoration(labelText: AppStrings.otpCode),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: AppStrings.password),
              obscureText: true,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.otpHint,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : (_otpSent ? _reset : _sendOtp),
            child: Text(
              _loading
                  ? AppStrings.processing
                  : (_otpSent ? AppStrings.resetPassword : AppStrings.sendOtp),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(AppStrings.backToLogin),
          ),
        ],
      ),
    );
  }
}
