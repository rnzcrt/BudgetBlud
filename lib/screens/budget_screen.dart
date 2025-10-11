import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import 'settings_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount.round());
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate total spending
    final totalSpent = expenseProvider.expenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final totalBudget = budgetProvider.totalBudget;
    final remainingTotal = totalBudget - totalSpent;

    // Calculate spending by category
    Map<String, double> categorySpending = {};
    for (var expense in expenseProvider.expenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Predefined categories
    final predefinedCategories = [
      'foods',
      'food',
      'transportation',
      'transport',
      'shopping',
      'bills',
      'housing',
    ];

    // Separate predefined and custom categories
    List<MapEntry<String, double>> predefinedSpending = [];
    List<MapEntry<String, double>> customSpending = [];

    for (var entry in categorySpending.entries) {
      if (predefinedCategories.contains(entry.key.toLowerCase())) {
        predefinedSpending.add(entry);
      } else {
        customSpending.add(entry);
      }
    }

    // Calculate remaining budget for custom categories
    final remainingBudget = budgetProvider.remainingBudget;
    final customCategoriesSpent = customSpending.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );
    final remainingForCustomCategories =
        remainingBudget - customCategoriesSpent;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Budget',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Month Header
            Text(
              'Current Month',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Total Spending Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Spending',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    Text(
                      _formatCurrency(totalSpent),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalBudget > 0
                      ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    remainingTotal >= 0 ? const Color(0xFF2563EB) : Colors.red,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining: ₱${_formatCurrency(remainingTotal)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: remainingTotal >= 0
                        ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Spending by Category Header
            Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Predefined Categories
            ...predefinedSpending.map((entry) {
              final category = entry.key;
              final spent = entry.value;
              final limit = _getCategoryLimit(category, budgetProvider);
              final remaining = limit - spent;

              return _buildCategoryItem(
                category: category,
                spent: spent,
                limit: limit,
                remaining: remaining,
                isDarkMode: isDarkMode,
              );
            }).toList(),

            // Custom Categories
            ...customSpending.map((entry) {
              final category = entry.key;
              final spent = entry.value;

              return _buildCategoryItem(
                category: category,
                spent: spent,
                limit: remainingBudget,
                remaining: remainingForCustomCategories,
                isDarkMode: isDarkMode,
                isCustom: true,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required double spent,
    required double limit,
    required double remaining,
    required bool isDarkMode,
    bool isCustom = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                _formatCurrency(spent),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              remaining >= 0 ? const Color(0xFF2563EB) : Colors.red,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining: ₱${_formatCurrency(remaining)}',
            style: TextStyle(
              fontSize: 12,
              color: remaining >= 0
                  ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  double _getCategoryLimit(String category, BudgetProvider budgetProvider) {
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
}
