import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  int _resetDay = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _resetDay = prefs.getInt('reset_day') ?? 1;
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
          // Theme Section
          _buildSectionTitle('Appearance', isDarkMode),
          _buildCard(
            isDarkMode,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.brightness_6,
                  title: 'Dark Mode',
                  isDarkMode: isDarkMode,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Language Section
          _buildSectionTitle('Language', isDarkMode),
          _buildCard(
            isDarkMode,
            child: _buildListTile(
              icon: Icons.language,
              title: 'Language',
              isDarkMode: isDarkMode,
              trailing: DropdownButton<String>(
                value: languageProvider.currentLanguage,
                underline: const SizedBox(),
                dropdownColor: isDarkMode
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
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
          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionTitle('Notifications', isDarkMode),
          _buildCard(
            isDarkMode,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.notifications,
                  title: 'Daily Reminders',
                  isDarkMode: isDarkMode,
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', value);

                      if (value) {
                        await NotificationService().scheduleDailyNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notifications enabled'),
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : null,
                            ),
                          );
                        }
                      } else {
                        await NotificationService().cancelAllNotifications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notifications disabled'),
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : null,
                            ),
                          );
                        }
                      }
                    },
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reset Date Section
          _buildSectionTitle('Budget Reset', isDarkMode),
          _buildCard(
            isDarkMode,
            child: _buildListTile(
              icon: Icons.calendar_today,
              title: 'Monthly Reset Day',
              subtitle: 'Day $_resetDay of each month',
              isDarkMode: isDarkMode,
              trailing: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => _showResetDayPicker(isDarkMode),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Export Section
          _buildSectionTitle('Data Management', isDarkMode),
          _buildCard(
            isDarkMode,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.download,
                  title: 'Export to CSV',
                  isDarkMode: isDarkMode,
                  onTap: () async {
                    try {
                      await ExportService().exportToCSV(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Data exported successfully'),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : null,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Export failed: $e'),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : null,
                          ),
                        );
                      }
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
                _buildListTile(
                  icon: Icons.picture_as_pdf,
                  title: 'Export to PDF',
                  isDarkMode: isDarkMode,
                  onTap: () async {
                    try {
                      await ExportService().exportToPDF(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('PDF exported successfully'),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : null,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Export failed: $e'),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : null,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white60 : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDarkMode, {required Widget child}) {
    return Card(
      elevation: 0,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required bool isDarkMode,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showResetDayPicker(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Select Reset Day',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 28,
            itemBuilder: (context, index) {
              final day = index + 1;
              return ListTile(
                title: Text(
                  'Day $day',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                selected: day == _resetDay,
                selectedTileColor: const Color(0xFF2563EB).withOpacity(0.2),
                onTap: () async {
                  setState(() {
                    _resetDay = day;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('reset_day', day);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
