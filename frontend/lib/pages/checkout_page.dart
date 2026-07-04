import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/toast_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../theme/responsive.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const _tipaxCost = 45000.0;

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController(text: 'ایران');
  final _cardNumber = TextEditingController(text: '4242 4242 4242 4242');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');
  final _discountCode = TextEditingController();

  List<UserAddress> _addresses = [];
  int? _selectedAddressId;
  bool _useManualAddress = true;
  String _shippingMethod = 'post';
  double _discountAmount = 0;
  String? _appliedDiscountCode;
  String? _discountMessage;
  bool _loadingAddresses = true;
  bool _submitting = false;
  bool _validatingDiscount = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await context.read<ApiService>().getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _loadingAddresses = false;
        if (list.isNotEmpty) {
          final defaultAddr = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
          _selectedAddressId = defaultAddr.id;
          _useManualAddress = false;
          _fillAddress(defaultAddr);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  void _fillAddress(UserAddress addr) {
    _firstName.text = addr.firstName;
    _lastName.text = addr.lastName;
    _address.text = addr.address;
    _city.text = addr.city;
    _state.text = addr.state;
    _zip.text = addr.zipCode;
    _country.text = addr.country;
  }

  double get _shippingCost => _shippingMethod == 'tipax' ? _tipaxCost : 0;

  double _orderTotal(double subtotal) => subtotal - _discountAmount + _shippingCost;

  Future<void> _applyDiscount(double subtotal) async {
    final code = _discountCode.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingDiscount = true);
    try {
      final result = await context.read<ApiService>().validateDiscount(code, subtotal);
      setState(() {
        _discountAmount = result.valid ? result.discountAmount : 0;
        _appliedDiscountCode = result.valid ? result.code : null;
        _discountMessage = result.message;
      });
    } catch (e) {
      setState(() => _discountMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _validatingDiscount = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'zip_code': _zip.text.trim(),
        'country': _country.text.trim(),
        'shipping_method': _shippingMethod,
        'card_number': _cardNumber.text.trim(),
        'expiry': _expiry.text.trim(),
        'cvv': _cvv.text.trim(),
        'items': cart.toCheckoutItems(),
      };
      if (_appliedDiscountCode != null) {
        payload['discount_code'] = _appliedDiscountCode;
      }
      if (!_useManualAddress && _selectedAddressId != null) {
        payload['saved_address_id'] = _selectedAddressId;
      }

      final result = await context.read<ApiService>().checkout(payload);
      cart.clear();
      setState(() => _orderId = result['order_id'] as String);
      context.showSuccess(AppStrings.toastOrderPlaced);
    } catch (e) {
      if (mounted) {
        context.showError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _country.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _discountCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final isMobile = AppResponsive.widthOf(context) < 900;
    final padding = AppResponsive.pagePadding(context);

    if (!auth.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.loginRequired),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/login'), child: const Text(AppStrings.login)),
          ],
        ),
      );
    }

    if (_orderId != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: AppColors.textPrimary.withValues(alpha: 0.6)),
              const SizedBox(height: 24),
              Text(
                AppStrings.thankYouOrder,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.orderSuccess(_orderId!),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/shop'),
                child: const Text(AppStrings.continueShopping),
              ),
            ],
          ),
        ),
      );
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.cartEmpty, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/shop'), child: const Text(AppStrings.browseProducts)),
          ],
        ),
      );
    }

    final form = _CheckoutForm(
      formKey: _formKey,
      firstName: _firstName,
      lastName: _lastName,
      address: _address,
      city: _city,
      state: _state,
      zip: _zip,
      country: _country,
      cardNumber: _cardNumber,
      expiry: _expiry,
      cvv: _cvv,
      addresses: _addresses,
      loadingAddresses: _loadingAddresses,
      selectedAddressId: _selectedAddressId,
      useManualAddress: _useManualAddress,
      shippingMethod: _shippingMethod,
      onAddressSelected: (id) {
        setState(() {
          _selectedAddressId = id;
          _useManualAddress = false;
          final addr = _addresses.firstWhere((a) => a.id == id);
          _fillAddress(addr);
        });
      },
      onManualSelected: () => setState(() => _useManualAddress = true),
      onShippingChanged: (method) => setState(() => _shippingMethod = method),
    );

    final summary = _OrderSummary(
      cart: cart,
      submitting: _submitting,
      discountCode: _discountCode,
      discountAmount: _discountAmount,
      shippingCost: _shippingCost,
      total: _orderTotal(cart.subtotal),
      validatingDiscount: _validatingDiscount,
      discountMessage: _discountMessage,
      onApplyDiscount: () => _applyDiscount(cart.subtotal),
      onSubmit: _submit,
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.checkout,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 32),
            if (isMobile) ...[
              form,
              const SizedBox(height: 32),
              summary,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: form),
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: summary),
                ],
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.formKey,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.addresses,
    required this.loadingAddresses,
    required this.selectedAddressId,
    required this.useManualAddress,
    required this.shippingMethod,
    required this.onAddressSelected,
    required this.onManualSelected,
    required this.onShippingChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;
  final TextEditingController country;
  final TextEditingController cardNumber;
  final TextEditingController expiry;
  final TextEditingController cvv;
  final List<UserAddress> addresses;
  final bool loadingAddresses;
  final int? selectedAddressId;
  final bool useManualAddress;
  final String shippingMethod;
  final ValueChanged<int> onAddressSelected;
  final VoidCallback onManualSelected;
  final ValueChanged<String> onShippingChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: AppStrings.shippingAddress),
          const SizedBox(height: 16),
          if (loadingAddresses)
            const AppLoadingBar(size: 36)
          else if (addresses.isNotEmpty) ...[
            RadioListTile<int?>(
              value: null,
              groupValue: useManualAddress ? null : selectedAddressId,
              onChanged: (_) => onManualSelected(),
              title: const Text(AppStrings.newAddress),
            ),
            ...addresses.map(
              (addr) => RadioListTile<int>(
                value: addr.id,
                groupValue: useManualAddress ? null : selectedAddressId,
                onChanged: (v) {
                  if (v != null) onAddressSelected(v);
                },
                title: Text('${addr.label}${addr.isDefault ? ' (پیش‌فرض)' : ''}'),
                subtitle: Text(addr.summary),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (useManualAddress || addresses.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: AppStrings.firstName),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: AppStrings.lastName),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: address,
              decoration: const InputDecoration(labelText: AppStrings.address),
              validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: city,
                    decoration: const InputDecoration(labelText: AppStrings.city),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: state,
                    decoration: const InputDecoration(labelText: AppStrings.state),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: zip,
                    decoration: const InputDecoration(labelText: AppStrings.zipCode),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: country,
                    decoration: const InputDecoration(labelText: AppStrings.country),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.required : null,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          _SectionTitle(title: AppStrings.shippingMethod),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'post',
            groupValue: shippingMethod,
            onChanged: (v) {
              if (v != null) onShippingChanged(v);
            },
            title: const Text(AppStrings.shippingPost),
          ),
          RadioListTile<String>(
            value: 'tipax',
            groupValue: shippingMethod,
            onChanged: (v) {
              if (v != null) onShippingChanged(v);
            },
            title: Text('${AppStrings.shippingTipax} — ${AppStrings.formatPrice(45000)}'),
          ),
          const SizedBox(height: 32),
          _SectionTitle(title: AppStrings.paymentPlaceholder),
          const SizedBox(height: 8),
          Text(
            AppStrings.paymentNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: cardNumber, decoration: const InputDecoration(labelText: AppStrings.cardNumber)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: expiry, decoration: const InputDecoration(labelText: AppStrings.expiry))),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: cvv, decoration: const InputDecoration(labelText: AppStrings.cvv))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.cart,
    required this.submitting,
    required this.discountCode,
    required this.discountAmount,
    required this.shippingCost,
    required this.total,
    required this.validatingDiscount,
    required this.onApplyDiscount,
    required this.onSubmit,
    this.discountMessage,
  });

  final CartProvider cart;
  final bool submitting;
  final TextEditingController discountCode;
  final double discountAmount;
  final double shippingCost;
  final double total;
  final bool validatingDiscount;
  final VoidCallback onApplyDiscount;
  final VoidCallback onSubmit;
  final String? discountMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.orderSummary, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.name} × ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(AppStrings.formatPrice(item.lineTotal)),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountCode,
                  decoration: const InputDecoration(
                    labelText: AppStrings.discountCode,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onApplyDiscount(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: validatingDiscount ? null : onApplyDiscount,
                child: Text(validatingDiscount ? '...' : AppStrings.applyDiscount),
              ),
            ],
          ),
          if (discountMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              discountMessage!,
              style: TextStyle(
                color: discountAmount > 0 ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _SummaryRow(label: AppStrings.subtotal, value: AppStrings.formatPrice(cart.subtotal)),
          if (discountAmount > 0)
            _SummaryRow(label: AppStrings.discount, value: '- ${AppStrings.formatPrice(discountAmount)}'),
          _SummaryRow(
            label: AppStrings.shippingCost,
            value: shippingCost == 0 ? AppStrings.shippingPost : AppStrings.formatPrice(shippingCost),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.total, style: Theme.of(context).textTheme.titleMedium),
              Text(
                AppStrings.formatPrice(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            child: Text(submitting ? AppStrings.processing : AppStrings.placeOrder),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 0.5),
    );
  }
}
