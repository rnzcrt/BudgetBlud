import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ADD THIS
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'services/supabase_service.dart';
import 'services/supabase_sync_service.dart';
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

            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  /// Setup auth state listener
  void _setupAuthListener() {
    // Listen to auth state changes
    SupabaseService().authStateChanges.listen((authState) {
      if (!mounted) return;

      final session = authState.session;

      if (session != null) {
        // User is authenticated
        debugPrint('✅ Auth state changed: User logged in');
        _handleAuthenticatedUser();
      } else {
        // User is not authenticated
        debugPrint('❌ Auth state changed: User logged out');
        if (_isInitialized) {
          _navigateToSplash();
        }
      }
    });

    // Initial check
    _checkInitialAuthState();
  }

  /// Check initial auth state on app start
  Future<void> _checkInitialAuthState() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final supabase = SupabaseService();

    if (supabase.isAuthenticated) {
      debugPrint('✅ Initial check: User is authenticated');
      await _handleAuthenticatedUser();
    } else {
      debugPrint('❌ Initial check: User not authenticated');
      _navigateToSplash();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  /// Handle authenticated user - load data and route
  Future<void> _handleAuthenticatedUser() async {
    final supabase = SupabaseService();
    debugPrint('🔵 Handling authenticated user: ${supabase.currentUserEmail}');

    if (!mounted) return;

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    // Clear old data first
    debugPrint('🔵 Clearing old provider data...');
    await budgetProvider.clearBudget();
    await expenseProvider.clearAllExpensesForLogout();

    // Small delay to ensure clear is complete
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Load fresh data from Supabase
    debugPrint('🔵 Loading data from Supabase...');

    // Load budget with retries
    bool budgetLoaded = false;
    for (int retry = 0; retry < 3; retry++) {
      await budgetProvider.reloadFromSupabase();

      // Wait for provider to be loaded
      int attempts = 0;
      while (!budgetProvider.isLoaded && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (budgetProvider.totalBudget > 0) {
        budgetLoaded = true;
        break;
      }

      debugPrint('⚠️ Retry $retry: Budget not loaded yet');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Load expenses
    await expenseProvider.syncFromSupabase();

    if (!mounted) return;

    debugPrint('🔵 Final budget: ₱${budgetProvider.totalBudget}');
    debugPrint('🔵 Final expenses: ${expenseProvider.expenses.length}');

    // Navigate based on budget
    if (budgetProvider.totalBudget > 0) {
      debugPrint('✅ Navigating to home');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      debugPrint('⚠️ Navigating to setup');
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const SetupScreen()));
    }
  }

  void _navigateToSplash() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
    );
  }
}
