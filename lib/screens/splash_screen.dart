import 'package:budgetblud/screens/onboarding_screen.dart';
import 'package:budgetblud/screens/main_navigation_screen.dart';
import 'package:budgetblud/services/monthly_check_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for 2 seconds for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if setup is complete
    final prefs = await SharedPreferences.getInstance();
    final setupComplete = prefs.getBool('setup_complete') ?? false;

    if (setupComplete) {
      // Check for new month and show dialog if needed
      await MonthlyCheckService.checkAndPromptForNewMonth(context);

      if (!mounted) return;

      // Navigate to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      // First time user - go to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/budget_blud.png', width: 260),
            const SizedBox(height: 24),
            const Text(
              "BudgetBlud",
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
