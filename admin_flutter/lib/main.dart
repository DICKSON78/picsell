import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/packages_screen.dart';
import 'screens/photos_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/photos_provider.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
    // Enable offline persistence so Firestore doesn't hang without network
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // Ensure default admin config exists in Firestore (non-blocking with timeout)
    AdminFirestoreService().ensureAdminDefaultsConfig().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  } catch (_) {
    // Firebase init failed - app will handle gracefully
  }

  runApp(const PicSellAdminApp());
}

class PicSellAdminApp extends StatelessWidget {
  const PicSellAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => PhotosProvider()),
      ],
      child: MaterialApp(
        title: 'PicSell Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside input fields
              FocusScope.of(context).unfocus();
            },
            child: child,
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const MainScreen(),
          '/customers': (context) => const CustomersScreen(),
          '/packages': (context) => const PackagesScreen(),
          '/photos': (context) => const PhotosScreen(),
          '/transactions': (context) => const TransactionsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/report-history': (context) => const ReportHistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/pending-approval': (context) => const PendingApprovalScreen(),
        },
      ),
    );
  }
}
