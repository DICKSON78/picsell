import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/localization_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/notifications_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/credits_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/generation_history_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/photo_processing_screen.dart';
import 'screens/faq_screen.dart';
import 'utils/theme.dart';
import 'services/notification_service.dart';

Future<void> initializeFirebase() async {
  // Check if Firebase is already initialized
  if (Firebase.apps.isNotEmpty) {
    debugPrint('Firebase already initialized');
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Don't rethrow - let the app continue and auth_service will handle it
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeFirebase();
  await NotificationService.initialize();
  runApp(const PicSellApp());
}

class PicSellApp extends StatelessWidget {
  const PicSellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
      child: MaterialApp(
        title: 'PicSell',
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
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/history': (context) => const HistoryScreen(),
          '/gallery': (context) => const GalleryScreen(),
          '/credits': (context) => const CreditsScreen(),
          '/account': (context) => const AccountSettingsScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/payment-methods': (context) => const PaymentMethodsScreen(),
          '/generation-history': (context) => const GenerationHistoryScreen(),
          '/help-support': (context) => const HelpSupportScreen(),
          '/help': (context) => const HelpSupportScreen(),
          '/photo-process': (context) => const PhotoProcessingScreen(),
          '/faq': (context) => const FAQScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
