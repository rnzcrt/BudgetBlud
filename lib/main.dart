import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:budgetblud/providers/budget_provider.dart';
import 'package:budgetblud/providers/expense_provider.dart';
import 'package:budgetblud/providers/theme_provider.dart';
import 'package:budgetblud/providers/language_provider.dart';
import 'package:budgetblud/services/notification_service.dart';
import 'package:budgetblud/l10n/app_localizations.dart';
import 'package:budgetblud/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const BudgetBludApp());
}

class BudgetBludApp extends StatelessWidget {
  const BudgetBludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetProvider>(create: (_) => BudgetProvider()),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'BudgetBlud',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: languageProvider.locale,
            localizationsDelegates: [
              // ← Changed from const to non-const
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('tl', 'PH'),
              Locale('es', 'ES'),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
