import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = Provider.of<BudgetProvider>(context).totalBudget;
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final categorySpent = <String, double>{};
    for (var e in expenses) {
      categorySpent[e.category] = (categorySpent[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          localizations.budget,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildProgress(
                localizations.totalSpending,
                totalSpent,
                budget,
                isDarkMode,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.spendingByCategory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ...categorySpent.entries.map((e) {
                double remaining = (budget / categorySpent.length) - e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildProgress(
                    e.key,
                    e.value,
                    (categorySpent.isNotEmpty)
                        ? budget / categorySpent.length
                        : budget,
                    isDarkMode,
                    remaining: remaining,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(
    String title,
    double value,
    double maxValue,
    bool isDarkMode, {
    double? remaining,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (maxValue > 0) ? (value / maxValue).clamp(0.0, 1.0) : 0.0,
          minHeight: 6,
          color: const Color(0xFF2563EB),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        ),
        const SizedBox(height: 4),
        if (remaining != null)
          Text(
            "Remaining: ₱${remaining.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.blueGrey,
            ),
          ),
      ],
    );
  }
}
