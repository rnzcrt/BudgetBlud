import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize notifications
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'BudgetBlud',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('tl', 'PH'),
              Locale('es', 'ES'),
            ],
            localizationsDelegates: const [AppLocalizations.delegate],
            home: const AuthWrapper(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/auth': (context) => const AuthScreen(),
              '/setup': (context) => const SetupScreen(),
              '/home': (context) => const MainNavigationScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Wrapper to handle authentication state and routing
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // Small delay to allow providers to initialize
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final supabase = SupabaseService();

    // Check if user is authenticated
    if (supabase.isAuthenticated) {
      debugPrint('✅ User is authenticated: ${supabase.currentUserEmail}');

      // IMPORTANT: Force reload all providers after login
      final budgetProvider = Provider.of<BudgetProvider>(
        context,
        listen: false,
      );
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      // Wait for budget provider to load
      int attempts = 0;
      while (!budgetProvider.isLoaded && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      // ADD THIS: Sync data from Supabase after login
      await expenseProvider.syncFromSupabase();
      await budgetProvider.reloadBudget();

      if (!mounted) return;

      if (budgetProvider.totalBudget > 0) {
        debugPrint('✅ Budget exists, going to home');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        debugPrint('⚠️ No budget found, going to setup');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
    } else {
      debugPrint('❌ User not authenticated, going to splash');
      // User not logged in, show splash
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
    );
  }
}
