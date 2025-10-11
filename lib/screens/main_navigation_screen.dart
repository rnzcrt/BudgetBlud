import 'package:flutter/material.dart';
import 'overview_screen.dart';
import 'budget_screen.dart';
import 'report_screen.dart';
import 'expenses_screen.dart';
import 'add_transaction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OverviewScreen(),
    const BudgetScreen(),
    const ReportScreen(),
    const ExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.home_outlined,
                Icons.home,
                "Overview",
                0,
                isDarkMode,
              ),
              _buildNavItem(
                Icons.attach_money_outlined,
                Icons.attach_money,
                "Budget",
                1,
                isDarkMode,
              ),
              const SizedBox(width: 40),
              _buildNavItem(
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                "Reports",
                2,
                isDarkMode,
              ),
              _buildNavItem(
                Icons.history,
                Icons.history,
                "Transactions",
                3,
                isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
    bool isDarkMode,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDarkMode ? Colors.white60 : Colors.grey),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDarkMode ? Colors.white60 : Colors.grey),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
