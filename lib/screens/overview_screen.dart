import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = Provider.of<BudgetProvider>(context).totalBudget;
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final percentage = budget == 0
        ? 0.0
        : (totalSpent / budget).clamp(0.0, 1.0);

    Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          localizations.dashboard,
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
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Donut Chart
              SizedBox(
                height: 220,
                width: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: totalSpent,
                            color: Colors.blue,
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (budget - totalSpent).clamp(0, budget),
                            color: Colors.blue.withOpacity(0.2),
                            radius: 25,
                            showTitle: false,
                          ),
                        ],
                        centerSpaceRadius: 70,
                        sectionsSpace: 0,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(percentage * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          "₱${totalSpent.toStringAsFixed(0)} ${localizations.spent}",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Progress
              Expanded(
                child: ListView(
                  children: categoryTotals.keys.map((category) {
                    final spent = categoryTotals[category]!;
                    final limit = _getCategoryLimit(category);
                    final left = limit - spent;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _getCategoryIcon(category, isDarkMode),
                                  const SizedBox(width: 8),
                                  Text(
                                    "/₱${limit.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                left >= 0
                                    ? "${localizations.left}: ₱${left.toStringAsFixed(0)}"
                                    : "${localizations.exceeded}: ₱${left.abs().toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: left >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (spent / limit).clamp(0.0, 1.0),
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              left >= 0 ? Colors.blue : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getCategoryLimit(String category) {
    switch (category) {
      case 'Food':
        return 200;
      case 'Entertainment':
        return 120;
      case 'Transport':
        return 20;
      case 'Housing':
        return 200;
      default:
        return 100;
    }
  }

  Widget _getCategoryIcon(String category, bool isDarkMode) {
    final iconColor = isDarkMode ? Colors.white70 : Colors.black;
    switch (category) {
      case 'Food':
        return Icon(Icons.restaurant, color: iconColor);
      case 'Entertainment':
        return Icon(Icons.sports_soccer, color: iconColor);
      case 'Transport':
        return Icon(Icons.directions_car, color: iconColor);
      case 'Housing':
        return Icon(Icons.home, color: iconColor);
      default:
        return Icon(Icons.category, color: iconColor);
    }
  }
}
