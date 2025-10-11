import 'package:flutter/material.dart';
import 'overview_screen.dart';
import 'budget_screen.dart';
import 'report_screen.dart';
import 'expenses_screen.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final screens = [
    const OverviewScreen(),
    const BudgetScreen(),
    const ReportScreen(),
    const ExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navButton(0, 'Overview', Icons.dashboard),
              _navButton(1, 'Budget', Icons.account_balance_wallet),
              const SizedBox(width: 50),
              _navButton(2, 'Reports', Icons.bar_chart),
              _navButton(3, 'Expenses', Icons.list),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(int index, String label, IconData icon) {
    return InkWell(
      onTap: () => setState(() => currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: currentIndex == index ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: currentIndex == index ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
