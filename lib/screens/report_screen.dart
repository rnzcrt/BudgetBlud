import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount.round());
  }

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final now = DateTime.now();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    // 1. Category totals for current month
    Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        categoryTotals[e.category] =
            (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }

    // 2. Monthly spending for last 6 months
    Map<String, double> monthlyTotals = {};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final key = _monthName(month.month);
      double total = expenses
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .fold(0.0, (sum, e) => sum + e.amount);
      monthlyTotals[key] = total;
    }

    // 3. Compare current month vs last month
    double lastMonthSpent = monthlyTotals.values.length > 1
        ? monthlyTotals.values.elementAt(monthlyTotals.values.length - 2)
        : 0.0;
    double currentMonthSpent = monthlyTotals.values.last;

    // Only calculate percentage if there was spending last month
    bool hasComparison = lastMonthSpent > 0;
    double comparisonPercent = hasComparison
        ? ((currentMonthSpent - lastMonthSpent) / lastMonthSpent * 100)
        : 0.0;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          localizations.reports,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Spending by Category
          Card(
            elevation: 2,
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.spendingByCategory,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${_formatCurrency(currentMonthSpent)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    localizations.thisMonth,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: categoryTotals.values.isEmpty
                            ? 100
                            : categoryTotals.values.reduce(
                                    (a, b) => a > b ? a : b,
                                  ) +
                                  50,
                        barGroups: categoryTotals.entries.map((e) {
                          return BarChartGroupData(
                            x: categoryTotals.keys.toList().indexOf(e.key),
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: _getCategoryColor(e.key),
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final int index = value.toInt();
                                final keys = categoryTotals.keys.toList();
                                if (index < 0 || index >= keys.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    keys[index],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Spending Trends
          Card(
            elevation: 2,
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.monthlySpendingTrends,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${_formatCurrency(currentMonthSpent)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  Text(
                    localizations.last6Months,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: monthlyTotals.values.isEmpty
                            ? 100
                            : monthlyTotals.values.reduce(
                                    (a, b) => a > b ? a : b,
                                  ) +
                                  50,
                        lineBarsData: [
                          LineChartBarData(
                            spots: monthlyTotals.entries.map((e) {
                              int x = monthlyTotals.keys.toList().indexOf(
                                e.key,
                              );
                              return FlSpot(x.toDouble(), e.value);
                            }).toList(),
                            isCurved: true,
                            barWidth: 3,
                            color: const Color(0xFF8B5CF6),
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= monthlyTotals.keys.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    monthlyTotals.keys.toList()[index],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Comparison
          Card(
            elevation: 2,
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.thisMonthVsLast,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${_formatCurrency(currentMonthSpent)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  hasComparison
                      ? Row(
                          children: [
                            Icon(
                              comparisonPercent >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: comparisonPercent >= 0
                                  ? Colors.red
                                  : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comparisonPercent.abs().toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: comparisonPercent >= 0
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              comparisonPercent >= 0 ? 'increase' : 'decrease',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'No previous month data',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : Colors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFEF4444);
      case 'Transportation':
        return const Color(0xFF3B82F6);
      case 'Entertainment':
        return const Color(0xFFF59E0B);
      case 'Utilities':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
