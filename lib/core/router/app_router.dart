import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/features/auth/screens/splash_screen.dart';
import 'package:peraco/features/auth/screens/welcome_screen.dart';
import 'package:peraco/features/auth/screens/login_screen.dart';
import 'package:peraco/features/auth/screens/signup_client_screen.dart';
import 'package:peraco/features/auth/screens/signup_farmer_screen.dart';
import 'package:peraco/features/auth/screens/signup_driver_screen.dart';
import 'package:peraco/features/client/home/screens/client_home_screen.dart';
import 'package:peraco/features/client/catalog/screens/client_catalog_screen.dart';
import 'package:peraco/features/client/cart/screens/client_cart_screen.dart';
import 'package:peraco/features/client/orders/screens/client_orders_screen.dart';
import 'package:peraco/features/client/product/screens/product_detail_screen.dart';
import 'package:peraco/features/client/checkout/screens/checkout_screen.dart';
import 'package:peraco/features/client/tracking/screens/tracking_screen.dart';
import 'package:peraco/features/farmer/dashboard/screens/farmer_dashboard_screen.dart';
import 'package:peraco/features/farmer/products/screens/farmer_products_screen.dart';
import 'package:peraco/features/farmer/orders/screens/farmer_orders_screen.dart';
import 'package:peraco/features/driver/deliveries/screens/driver_deliveries_screen.dart';
import 'package:peraco/features/driver/map/screens/driver_map_screen.dart';
import 'package:peraco/features/driver/history/screens/driver_history_screen.dart';
import 'package:peraco/features/profile/screens/profile_screen.dart';
import 'package:peraco/features/profile/screens/addresses_screen.dart';
import 'package:peraco/features/profile/screens/fiscal_screen.dart';
import 'package:peraco/shared/widgets/client_scaffold.dart';
import 'package:peraco/shared/widgets/farmer_scaffold.dart';
import 'package:peraco/shared/widgets/driver_scaffold.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signupClient = '/signup/client';
  static const String signupFarmer = '/signup/farmer';
  static const String signupDriver = '/signup/driver';
  // Client
  static const String clientHome = '/client';
  static const String clientCatalog = '/client/catalog';
  static const String clientCart = '/client/cart';
  static const String clientOrders = '/client/orders';
  static const String clientProfile = '/client/profile';
  static const String productDetail = '/client/product/:id';
  static const String checkout = '/client/checkout';
  static const String tracking = '/client/tracking/:id';
  static const String addresses = '/client/profile/addresses';
  static const String fiscal = '/client/profile/fiscal';
  // Farmer
  static const String farmerDashboard = '/farmer';
  static const String farmerProducts = '/farmer/products';
  static const String farmerOrders = '/farmer/orders';
  static const String farmerProfile = '/farmer/profile';
  // Driver
  static const String driverDeliveries = '/driver';
  static const String driverMap = '/driver/map';
  static const String driverHistory = '/driver/history';
  static const String driverProfile = '/driver/profile';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    // Auth
    GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
    GoRoute(path: AppRoutes.welcome, builder: (c, s) => const WelcomeScreen()),
    GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
    GoRoute(path: AppRoutes.signupClient, builder: (c, s) => const SignupClientScreen()),
    GoRoute(path: AppRoutes.signupFarmer, builder: (c, s) => const SignupFarmerScreen()),
    GoRoute(path: AppRoutes.signupDriver, builder: (c, s) => const SignupDriverScreen()),

    // Client shell
    StatefulShellRoute.indexedStack(
      builder: (c, s, nav) => ClientScaffold(navigationShell: nav),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/client', builder: (c, s) => const ClientHomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/client/catalog', builder: (c, s) => const ClientCatalogScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/client/cart', builder: (c, s) => const ClientCartScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/client/orders', builder: (c, s) => const ClientOrdersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/client/profile',
            builder: (c, s) => const ProfileScreen(),
            routes: [
              GoRoute(path: 'addresses', builder: (c, s) => const AddressesScreen()),
              GoRoute(path: 'fiscal', builder: (c, s) => const FiscalScreen()),
            ],
          ),
        ]),
      ],
    ),

    // Client full-screen routes
    GoRoute(path: '/client/product/:id', builder: (c, s) => ProductDetailScreen(productId: s.pathParameters['id']!)),
    GoRoute(path: '/client/checkout', builder: (c, s) => const CheckoutScreen()),
    GoRoute(path: '/client/tracking/:id', builder: (c, s) => TrackingScreen(orderId: s.pathParameters['id']!)),

    // Farmer shell
    StatefulShellRoute.indexedStack(
      builder: (c, s, nav) => FarmerScaffold(navigationShell: nav),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/farmer', builder: (c, s) => const FarmerDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/farmer/products', builder: (c, s) => const FarmerProductsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/farmer/orders', builder: (c, s) => const FarmerOrdersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/farmer/profile', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),

    // Driver shell
    StatefulShellRoute.indexedStack(
      builder: (c, s, nav) => DriverScaffold(navigationShell: nav),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/driver', builder: (c, s) => const DriverDeliveriesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/driver/map', builder: (c, s) => const DriverMapScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/driver/history', builder: (c, s) => const DriverHistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/driver/profile', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
