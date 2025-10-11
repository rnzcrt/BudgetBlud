import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String search = '';
  String? filterCategory;
  String? filterSort;
  String? filterMonth;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get all unique categories from expenses
    final allCategories = provider.expenses
        .map((e) => e.category)
        .toSet()
        .toList();

    // Define predefined categories (matching your budget provider)
    final predefinedCategories = [
      'Foods',
      'Transportation',
      'Shopping',
      'Bills',
    ];

    // Get custom categories (anything not in predefined list)
    final customCategories = allCategories
        .where((c) => !predefinedCategories.contains(c))
        .toList();

    // Build category filter list
    List<String> categories = [
      ...predefinedCategories.where((c) => allCategories.contains(c)),
      if (customCategories.isNotEmpty) 'Others',
    ];

    final months = provider.expenses
        .map((e) => DateFormat('MMMM yyyy').format(e.date))
        .toSet()
        .toList();

    List<Expense> filtered = provider.expenses.where((e) {
      bool matchesSearch =
          (e.note?.toLowerCase() ?? '').contains(search.toLowerCase()) ||
          (e.category?.toLowerCase() ?? '').contains(search.toLowerCase()) ||
          e.amount.toString().contains(search);

      bool matchesCategory = true;
      if (filterCategory != null) {
        if (filterCategory == 'Others') {
          matchesCategory = customCategories.contains(e.category);
        } else {
          matchesCategory = e.category == filterCategory;
        }
      }

      bool matchesMonth =
          filterMonth == null ||
          DateFormat('MMMM yyyy').format(e.date) == filterMonth;

      return matchesSearch && matchesCategory && matchesMonth;
    }).toList();

    if (filterSort == 'Low to High') {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (filterSort == 'High to Low') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'Expenses',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF2C2C2C)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              onChanged: (val) => setState(() => search = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFilterDropdown(
                  title: "Category",
                  value: filterCategory,
                  items: categories,
                  onChanged: (val) => setState(() => filterCategory = val),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  title: "Month",
                  value: filterMonth,
                  items: months,
                  onChanged: (val) => setState(() => filterMonth = val),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  title: "Amount",
                  value: filterSort,
                  items: ["Low to High", "High to Low"],
                  onChanged: (val) => setState(() => filterSort = val),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    search = '';
                    filterCategory = null;
                    filterSort = null;
                    filterMonth = null;
                  });
                },
                child: const Text("Reset Filters"),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No expenses found',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      final formattedAmount = NumberFormat(
                        '#,##0.00',
                      ).format(e.amount);

                      return Dismissible(
                        key: ValueKey(e.id),
                        background: SizedBox.expand(
                          child: Container(
                            color: Colors.green,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                        secondaryBackground: SizedBox.expand(
                          child: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.white,
                                title: Text(
                                  "Confirm Delete",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                content: Text(
                                  "Are you sure you want to delete this transaction?",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddTransactionScreen(expense: e),
                              ),
                            );
                            return false;
                          }
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            provider.deleteExpense(e.id);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _getCategoryIcon(e.category, isDarkMode),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "₱$formattedAmount",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      e.category,
                                      style: const TextStyle(
                                        color: Color(0xFF61738A),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(e.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 13,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            alignment: AlignmentDirectional.centerStart,
            menuMaxHeight: 300,
            items: items
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category, bool isDarkMode) {
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    // Match icons from overview_screen.dart
    switch (category.toLowerCase()) {
      case 'food':
      case 'foods':
        return Icon(Icons.restaurant, color: iconColor);
      case 'transportation':
      case 'transport':
        return Icon(Icons.directions_car, color: iconColor);
      case 'shopping':
        return Icon(Icons.shopping_bag, color: iconColor);
      case 'bills':
      case 'housing':
        return Icon(Icons.receipt_long, color: iconColor);
      default:
        return Icon(Icons.attach_money, color: iconColor);
    }
  }
}
