import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final budget = budgetProvider.totalBudget;
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final percentage = budget == 0
        ? 0.0
        : (totalSpent / budget).clamp(0.0, 1.0);

    // Calculate category totals
    Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    // Calculate remaining budget (budget left after predefined categories)
    final remainingBudget = budgetProvider.remainingBudget;

    // Get all custom categories
    final predefinedCategories = [
      'foods',
      'food',
      'transportation',
      'transport',
      'shopping',
      'bills',
      'housing',
    ];

    // Calculate total spent on custom categories
    double customCategoriesSpent = 0.0;
    for (var entry in categoryTotals.entries) {
      if (!predefinedCategories.contains(entry.key.toLowerCase())) {
        customCategoriesSpent += entry.value;
      }
    }

    // Remaining budget for custom categories
    final remainingForCustomCategories =
        remainingBudget - customCategoriesSpent;

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Donut Chart - Maximized width
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Center(
                  child: SizedBox(
                    height: 280,
                    width: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: _buildChartSections(
                              totalSpent,
                              budget,
                              percentage,
                            ),
                            centerSpaceRadius: 85,
                            sectionsSpace: 0,
                            startDegreeOffset: 270,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(percentage * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF346EDA),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₱${_formatCurrency(totalSpent)} ${localizations.spent}",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Category Progress
              Expanded(
                child: ListView.separated(
                  itemCount: categoryTotals.keys.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final category = categoryTotals.keys.elementAt(index);
                    final spent = categoryTotals[category]!;
                    final isCustomCategory = !predefinedCategories.contains(
                      category.toLowerCase(),
                    );

                    final limit = isCustomCategory
                        ? remainingBudget
                        : _getPredefinedCategoryLimit(category, budgetProvider);

                    final left = isCustomCategory
                        ? remainingForCustomCategories
                        : limit - spent;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "$category /₱${_formatCurrency(limit)}",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  left >= 0
                                      ? "${localizations.left}: ₱${_formatCurrency(left)}"
                                      : "${localizations.exceeded}: ₱${_formatCurrency(left.abs())}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: left >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _getCategoryIcon(category, isDarkMode),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: isCustomCategory
                                      ? (customCategoriesSpent /
                                                remainingBudget)
                                            .clamp(0.0, 1.0)
                                      : (spent / limit).clamp(0.0, 1.0),
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    left >= 0
                                        ? const Color(0xFF346EDA)
                                        : Colors.red,
                                  ),
                                  minHeight: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(
    double totalSpent,
    double budget,
    double percentage,
  ) {
    // Colors from Figma design
    final spentColor1 = const Color(0xFF346EDA);
    final spentColor2 = const Color(0xFF48A8DF);
    final remainingColor1 = const Color(0xFFB8C5E0);
    final remainingColor2 = const Color(0xFFD4DCF0);

    final remaining = (budget - totalSpent).clamp(0, budget);

    // Create gradient effect by splitting sections
    if (totalSpent > 0 && remaining > 0) {
      return [
        // Spent section - darker blue
        PieChartSectionData(
          value: totalSpent * 0.6,
          color: spentColor1,
          radius: 40,
          showTitle: false,
        ),
        // Spent section - lighter blue
        PieChartSectionData(
          value: totalSpent * 0.4,
          color: spentColor2,
          radius: 40,
          showTitle: false,
        ),
        // Remaining section - light gray
        PieChartSectionData(
          value: remaining * 0.6,
          color: remainingColor1,
          radius: 40,
          showTitle: false,
        ),
        // Remaining section - lighter gray
        PieChartSectionData(
          value: remaining * 0.4,
          color: remainingColor2,
          radius: 40,
          showTitle: false,
        ),
      ];
    } else if (totalSpent > 0) {
      return [
        PieChartSectionData(
          value: totalSpent * 0.6,
          color: spentColor1,
          radius: 40,
          showTitle: false,
        ),
        PieChartSectionData(
          value: totalSpent * 0.4,
          color: spentColor2,
          radius: 40,
          showTitle: false,
        ),
      ];
    } else {
      return [
        PieChartSectionData(
          value: budget,
          color: remainingColor1,
          radius: 40,
          showTitle: false,
        ),
      ];
    }
  }

  double _getPredefinedCategoryLimit(
    String category,
    BudgetProvider budgetProvider,
  ) {
    switch (category.toLowerCase()) {
      case 'foods':
      case 'food':
        return budgetProvider.foodsLimit;
      case 'transportation':
      case 'transport':
        return budgetProvider.transportationLimit;
      case 'shopping':
        return budgetProvider.shoppingLimit;
      case 'bills':
      case 'housing':
        return budgetProvider.billsLimit;
      default:
        return 0.0;
    }
  }

  Widget _getCategoryIcon(String category, bool isDarkMode) {
    final iconColor = isDarkMode ? Colors.white70 : Colors.black;
    final iconSize = 24.0;

    switch (category.toLowerCase()) {
      case 'foods':
      case 'food':
        return Icon(Icons.restaurant, color: iconColor, size: iconSize);
      case 'shopping':
        return Icon(Icons.shopping_bag, color: iconColor, size: iconSize);
      case 'transportation':
      case 'transport':
        return Icon(Icons.directions_car, color: iconColor, size: iconSize);
      case 'bills':
      case 'housing':
        return Icon(Icons.receipt_long, color: iconColor, size: iconSize);
      default:
        return Icon(Icons.attach_money, color: iconColor, size: iconSize);
    }
  }
}
