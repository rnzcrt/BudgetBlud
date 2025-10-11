import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = false;
  bool _budgetAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled =
          prefs.getBool('push_notifications_enabled') ?? false;
      _budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionTitle('Notifications', isDarkMode),
          const SizedBox(height: 8),
          _buildNotificationItem(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Enable or disable push notifications',
            value: _pushNotificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _pushNotificationsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('push_notifications_enabled', value);

              if (value) {
                await NotificationService().scheduleDailyNotification();
                if (mounted) {
                  _showSnackBar('Push notifications enabled', isDarkMode);
                }
              } else {
                await NotificationService().cancelAllNotifications();
                if (mounted) {
                  _showSnackBar('Push notifications disabled', isDarkMode);
                }
              }
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.info_outline,
            title: 'Budget Alerts',
            subtitle: 'Enable or disable budget alert at 80%',
            value: _budgetAlertsEnabled,
            onChanged: (value) async {
              setState(() {
                _budgetAlertsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('budget_alerts_enabled', value);
              if (mounted) {
                _showSnackBar(
                  value ? 'Budget alerts enabled' : 'Budget alerts disabled',
                  isDarkMode,
                );
              }
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionTitle('Data Management', isDarkMode),
          const SizedBox(height: 8),
          _buildActionItem(
            icon: Icons.refresh,
            title: 'Reset App Data',
            subtitle: 'Will wipe all the existing data',
            onTap: () => _showResetConfirmation(isDarkMode),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildActionItem(
            icon: Icons.file_download_outlined,
            title: 'Export Data',
            subtitle: 'Export Data to PDF/CSV',
            onTap: () => _showExportOptions(isDarkMode),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionTitle('App Settings', isDarkMode),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.brightness_6_outlined,
            title: 'Display',
            subtitle: 'Choose between light and dark',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
              activeColor: const Color(0xFF2563EB),
            ),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'Select your preferred language',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: languageProvider.currentLanguage,
                  dropdownColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'tl', child: Text('Tagalog')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.setLanguage(value);
                    }
                  },
                ),
              ),
            ),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.assignment_outlined,
            title: 'Version',
            subtitle: 'BudgetBlud v1.0',
            trailing: const SizedBox.shrink(),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white70 : Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showSnackBar(String message, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isDarkMode
            ? const Color(0xFF2C2C2C)
            : const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetConfirmation(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Reset App Data',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all app data? This action cannot be undone and will delete all your expenses and budget settings.',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final expenseProvider = Provider.of<ExpenseProvider>(
                context,
                listen: false,
              );
              final budgetProvider = Provider.of<BudgetProvider>(
                context,
                listen: false,
              );

              await expenseProvider.clearAllExpenses();
              await budgetProvider.resetBudget();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SetupScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green),
              ),
              title: Text(
                'Export to CSV',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Export data as CSV file',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ExportService().exportToCSV(context);
                  if (mounted) {
                    _showSnackBar(
                      'Data exported to CSV successfully',
                      isDarkMode,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Export failed: $e', isDarkMode);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: Text(
                'Export to PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Export data as PDF file',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ExportService().exportToPDF(context);
                  if (mounted) {
                    _showSnackBar(
                      'Data exported to PDF successfully',
                      isDarkMode,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Export failed: $e', isDarkMode);
                  }
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
