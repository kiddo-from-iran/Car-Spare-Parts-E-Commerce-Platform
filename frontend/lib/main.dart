import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/toast_provider.dart';
import 'providers/wishlist_provider.dart';
import 'router.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_toast_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuratedApp());
}

class CuratedApp extends StatefulWidget {
  const CuratedApp({super.key});

  @override
  State<CuratedApp> createState() => _CuratedAppState();
}

class _CuratedAppState extends State<CuratedApp> {
  late final ApiService _api;
  late final AuthProvider _auth;
  late final GoRouterHolder _routerHolder;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _auth = AuthProvider(_api)..init();
    _routerHolder = GoRouterHolder(createRouter(_auth));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _api),
        ChangeNotifierProvider(create: (_) => ToastProvider()),
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProxyProvider<ToastProvider, CartProvider>(
          create: (ctx) => CartProvider(ctx.read<ToastProvider>()),
          update: (_, toast, cart) => cart ?? CartProvider(toast),
        ),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp.router(
        title: 'جهانگیری',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.theme,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AppToastOverlay(child: child!),
          );
        },
        routerConfig: _routerHolder.router,
      ),
    );
  }
}

class GoRouterHolder {
  GoRouterHolder(this.router);
  final GoRouter router;
}
