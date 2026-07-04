import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/toast_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.showSuccess('پیام شما با موفقیت ارسال شد');
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);
    final isMobile = AppResponsive.isPhone(context);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Header(),
              const SizedBox(height: 32),
              _ContactInfo(),
              const SizedBox(height: 32),
              _ContactForm(
                formKey: _formKey,
                name: _nameController,
                phone: _phoneController,
                email: _emailController,
                message: _messageController,
                onSubmit: _submit,
              ),
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Header(),
                  const SizedBox(height: 32),
                  _ContactInfo(),
                ])),
                const SizedBox(width: 48),
                Expanded(
                  child: _ContactForm(
                    formKey: _formKey,
                    name: _nameController,
                    phone: _phoneController,
                    email: _emailController,
                    message: _messageController,
                    onSubmit: _submit,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(AppStrings.contactTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('ما آماده پاسخگویی به سوالات شما هستیم',
            style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ContactInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.store_outlined, label: 'فروشگاه', value: AppStrings.storePhone),
          const Divider(height: 32),
          _InfoRow(icon: Icons.headset_mic_outlined, label: 'پشتیبانی', value: AppStrings.supportPhone),
          const Divider(height: 32),
          _InfoRow(icon: Icons.send_outlined, label: 'تلگرام', value: AppStrings.telegramId),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.name,
    required this.phone,
    required this.email,
    required this.message,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController message;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [AppTheme.softShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.sendMessage, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: AppStrings.name),
              validator: (v) => v == null || v.isEmpty ? 'الزامی' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phone,
              decoration: const InputDecoration(labelText: AppStrings.phone),
              validator: (v) => v == null || v.isEmpty ? 'الزامی' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: AppStrings.email),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: message,
              decoration: const InputDecoration(labelText: AppStrings.message),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'الزامی' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onSubmit, child: const Text(AppStrings.sendMessage)),
          ],
        ),
      ),
    );
  }
}
