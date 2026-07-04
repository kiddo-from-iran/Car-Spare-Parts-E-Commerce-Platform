import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../providers/toast_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/luxury_animations.dart';
import '../widgets/map_embed.dart';

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
    final isTablet = AppResponsive.isTablet(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(child: const _PageHero()),
                SizedBox(height: isMobile ? 40 : 56),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(delay: const Duration(milliseconds: 80), child: const _ContactChannels()),
                      const SizedBox(height: 28),
                      FadeSlideIn(delay: const Duration(milliseconds: 120), child: const _LocationCard()),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: _ContactFormCard(
                          formKey: _formKey,
                          name: _nameController,
                          phone: _phoneController,
                          email: _emailController,
                          message: _messageController,
                          onSubmit: _submit,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isTablet ? 5 : 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 80),
                              child: const _ContactChannels(),
                            ),
                            const SizedBox(height: 28),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 140),
                              child: const _LocationCard(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isTablet ? 28 : 40),
                      Expanded(
                        flex: isTablet ? 6 : 5,
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: _ContactFormCard(
                            formKey: _formKey,
                            name: _nameController,
                            phone: _phoneController,
                            email: _emailController,
                            message: _messageController,
                            onSubmit: _submit,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHero extends StatelessWidget {
  const _PageHero();

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isPhone(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: isMobile ? 32 : 44),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: isMobile ? 72 : 88,
            margin: const EdgeInsetsDirectional.only(end: 24),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تماس با جهانگیری',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.contactTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'تیم پشتیبانی ما آماده پاسخگویی به سوالات فنی، سفارش‌ها و همکاری‌های تجاری شماست.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.72),
                        height: 1.75,
                      ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.support_agent_outlined, color: AppColors.gold, size: 34),
            ),
        ],
      ),
    );
  }
}

class _ContactChannels extends StatelessWidget {
  const _ContactChannels();

  static String _latinPhone(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var out = value;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(persian[i], '$i');
    }
    return out.replaceAll(RegExp(r'[\s\-]'), '');
  }

  static final _channels = [
    (
      icon: Icons.storefront_outlined,
      label: 'فروشگاه',
      value: AppStrings.storePhone,
      hint: 'سفارش و موجودی',
      uri: Uri.parse('tel:${_latinPhone(AppStrings.storePhone)}'),
    ),
    (
      icon: Icons.headset_mic_outlined,
      label: 'پشتیبانی',
      value: AppStrings.supportPhone,
      hint: 'پاسخگویی سریع',
      uri: Uri.parse('tel:${_latinPhone(AppStrings.supportPhone)}'),
    ),
    (
      icon: Icons.send_outlined,
      label: 'تلگرام',
      value: AppStrings.telegramId,
      hint: 'پیام فوری',
      uri: Uri.parse('https://t.me/${AppStrings.telegramId.replaceFirst('@', '')}'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'راه‌های ارتباطی', subtitle: 'مستقیم با ما در تماس باشید'),
        const SizedBox(height: 20),
        for (var i = 0; i < _channels.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _ChannelCard(
            icon: _channels[i].icon,
            label: _channels[i].label,
            value: _channels[i].value,
            hint: _channels[i].hint,
            onTap: () => launchUrl(_channels[i].uri),
          ),
        ],
        const SizedBox(height: 14),
        _PremiumCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.schedule_outlined, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ساعات پاسخگویی',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'شنبه تا پنج‌شنبه · ۹:۰۰ تا ۱۸:۰۰',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatefulWidget {
  const _ChannelCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColors.gold.withValues(alpha: 0.45) : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [AppTheme.softShadow],
          ),
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.gold.withValues(alpha: 0.14) : AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.hint,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: _hovered ? AppColors.gold : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'موقعیت فروشگاه', subtitle: AppStrings.aboutAddress),
        const SizedBox(height: 20),
        _PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: const MapEmbed(height: 220),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.location_on_outlined, color: AppColors.gold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'آدرس',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.aboutAddress,
                            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactFormCard extends StatelessWidget {
  const _ContactFormCard({
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
    return _PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.sendMessage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'فرم زیر را تکمیل کنید تا در اسرع وقت با شما تماس بگیریم.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormField(
                    controller: name,
                    label: AppStrings.name,
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty ? 'الزامی' : null,
                  ),
                  const SizedBox(height: 18),
                  _FormField(
                    controller: phone,
                    label: AppStrings.phone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'الزامی' : null,
                  ),
                  const SizedBox(height: 18),
                  _FormField(
                    controller: email,
                    label: AppStrings.email,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _FormField(
                    controller: message,
                    label: AppStrings.message,
                    icon: Icons.chat_bubble_outline,
                    maxLines: 5,
                    validator: (v) => v == null || v.trim().isEmpty ? 'الزامی' : null,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send_outlined, size: 20),
                    label: const Text(AppStrings.sendMessage),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.textOnGold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppTheme.softShadow],
      ),
      child: child,
    );
  }
}
