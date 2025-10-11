import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/setup_screen.dart';

class MonthlyCheckService {
  static const String _lastResetMonthKey = 'last_reset_month';
  static const String _lastResetYearKey = 'last_reset_year';
  static const int _gracePeriodDays = 3;

  /// Check if it's a new month and show dialog if needed
  static Future<void> checkAndPromptForNewMonth(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastResetMonth = prefs.getInt(_lastResetMonthKey);
    final lastResetYear = prefs.getInt(_lastResetYearKey);

    // First time user - save current month
    if (lastResetMonth == null || lastResetYear == null) {
      await _saveCurrentMonth(prefs, now);
      return;
    }

    // Check if we're in a new month
    final isNewMonth = now.month != lastResetMonth || now.year != lastResetYear;

    if (isNewMonth) {
      // Check if we're within grace period
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final daysSinceMonthStart = now.difference(firstDayOfMonth).inDays;
      final isWithinGracePeriod = daysSinceMonthStart < _gracePeriodDays;

      // Check if dialog was already shown this month
      final dialogShownKey = 'dialog_shown_${now.year}_${now.month}';
      final dialogAlreadyShown = prefs.getBool(dialogShownKey) ?? false;

      if (!dialogAlreadyShown && context.mounted) {
        await _showMonthlyResetDialog(
          context,
          isWithinGracePeriod,
          lastResetMonth,
          lastResetYear,
        );
        // Mark dialog as shown for this month
        await prefs.setBool(dialogShownKey, true);
      }
    }
  }

  /// Save current month as last reset month
  static Future<void> _saveCurrentMonth(
    SharedPreferences prefs,
    DateTime date,
  ) async {
    await prefs.setInt(_lastResetMonthKey, date.month);
    await prefs.setInt(_lastResetYearKey, date.year);
  }

  /// Show the monthly reset dialog
  static Future<void> _showMonthlyResetDialog(
    BuildContext context,
    bool isWithinGracePeriod,
    int lastMonth,
    int lastYear,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFF2563EB),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'New Month! 🎉',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to ${monthNames[now.month - 1]}!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Let\'s renew your budget for this month and set limits for each category.',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (isWithinGracePeriod) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Grace period: You can still add expenses to ${monthNames[lastMonth - 1]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '📊 Your previous data will be preserved in Reports',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // User chose to continue without resetting
              // Mark as acknowledged but don't reset
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(
                'budget_reset_postponed_${now.year}_${now.month}',
                true,
              );
            },
            child: Text(
              'Later',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Save current month as reset month
              final prefs = await SharedPreferences.getInstance();
              await _saveCurrentMonth(prefs, now);

              // Navigate to setup screen with renewal mode
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SetupScreen(isRenewal: true),
                  ),
                );
              }
            },
            child: const Text(
              'Renew Budget',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Manually trigger monthly reset (for testing or manual reset)
  static Future<void> manuallyResetMonth() async {
    final prefs = await SharedPreferences.getInstance();
    await _saveCurrentMonth(prefs, DateTime.now());
  }

  /// Get last reset date
  static Future<DateTime?> getLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final month = prefs.getInt(_lastResetMonthKey);
    final year = prefs.getInt(_lastResetYearKey);

    if (month == null || year == null) return null;
    return DateTime(year, month);
  }

  /// Clear monthly check dialog flag (for testing)
  static Future<void> clearDialogShownFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dialogShownKey = 'dialog_shown_${now.year}_${now.month}';
    await prefs.remove(dialogShownKey);
  }
}
