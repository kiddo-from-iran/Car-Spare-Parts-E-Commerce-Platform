import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import 'account_shell.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final wishlist = context.read<WishlistProvider>();
    if (wishlist.ids.isEmpty) {
      setState(() {
        _products = [];
        _loading = false;
      });
      return;
    }
    try {
      final api = context.read<ApiService>();
      final all = await api.getProducts();
      if (mounted) {
        setState(() {
          _products = all.where((p) => wishlist.isWishlisted(p.id)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountPageShell(
      title: AppStrings.myWishlist,
      child: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _products.isEmpty
              ? Center(
                  child: Text('لیست علاقه‌مندی‌ها خالی است', style: TextStyle(color: AppColors.textMuted)),
                )
              : ProductGrid(products: _products),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      ('سفارش #JG-1001', 'سفارش شما در حال پردازش است', '۲ ساعت پیش', Icons.local_shipping_outlined),
      ('تخفیف ویژه', '۱۰٪ تخفیف برای خرید بالای ۵ میلیون تومان', '۱ روز پیش', Icons.local_offer_outlined),
      ('موجود شد', 'لنت ترمز پژو ۴۰۵ موجود شد', '۳ روز پیش', Icons.inventory_2_outlined),
    ];

    return AccountPageShell(
      title: AppStrings.notifications,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (title, body, time, icon) = notifications[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(body, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(time, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
