import 'package:go_router/go_router.dart';

import '../pages/about_page.dart';
import '../pages/account/addresses_page.dart';
import '../pages/account/profile_page.dart';
import '../pages/account/order_detail_page.dart';
import '../pages/account/my_orders_page.dart';
import '../pages/account/wishlist_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/admin_orders_page.dart';
import '../pages/admin/admin_products_page.dart';
import '../pages/admin/admin_revenue_page.dart';
import '../pages/admin/admin_shell.dart';
import '../pages/admin/admin_tickets_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/checkout_page.dart';
import '../pages/contact_page.dart';
import '../pages/home_page.dart';
import '../pages/product_detail_page.dart';
import '../pages/smart_catalog/smart_catalog_page.dart';
import '../pages/shop_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_layout.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.loading) return null;

      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register' || path == '/forgot-password';
      final isAdminRoute = path.startsWith('/admin');
      final isAccountRoute = path.startsWith('/account');

      if ((isAdminRoute || isAccountRoute || path == '/checkout') && !auth.isLoggedIn) {
        return '/login';
      }
      if (isAdminRoute && !auth.isAdmin) {
        return '/';
      }
      if (auth.isLoggedIn && isAuthRoute) {
        return auth.isAdmin ? '/admin' : '/account/orders';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/shop',
            builder: (context, state) => ShopPage(
              initialCategory: state.uri.queryParameters['category'],
              initialSearch: state.uri.queryParameters['search'],
              initialVehicle: state.uri.queryParameters['vehicle'],
              initialPartCategory: state.uri.queryParameters['part_category'],
            ),
          ),
          GoRoute(path: '/smart-catalog', builder: (context, state) => const SmartCatalogPage()),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) =>
                ProductDetailPage(productId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
          GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
          GoRoute(path: '/contact', builder: (context, state) => const ContactPage()),
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
          GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
          GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
          GoRoute(path: '/account/profile', builder: (context, state) => const ProfilePage()),
          GoRoute(path: '/account/addresses', builder: (context, state) => const AddressesPage()),
          GoRoute(path: '/account/orders', builder: (context, state) => const MyOrdersPage()),
          GoRoute(
            path: '/account/orders/:id',
            builder: (context, state) =>
                OrderDetailPage(orderId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/account/wishlist', builder: (context, state) => const WishlistPage()),
          GoRoute(path: '/account/notifications', builder: (context, state) => const NotificationsPage()),
          GoRoute(path: '/account/tickets', builder: (context, state) => const MyTicketsPage()),
          GoRoute(
            path: '/account/tickets/:id',
            builder: (context, state) =>
                TicketDetailPage(ticketId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: AdminShell(child: child)),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
          GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrdersPage()),
          GoRoute(path: '/admin/products', builder: (context, state) => const AdminProductsPage()),
          GoRoute(path: '/admin/revenue', builder: (context, state) => const AdminRevenuePage()),
          GoRoute(path: '/admin/tickets', builder: (context, state) => const AdminTicketsPage()),
          GoRoute(
            path: '/admin/tickets/:id',
            builder: (context, state) =>
                AdminTicketDetailPage(ticketId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
}
