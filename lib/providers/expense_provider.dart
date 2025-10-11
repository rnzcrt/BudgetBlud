import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  ExpenseProvider() {
    _loadExpenses();
  }

  // Load expenses from SharedPreferences
  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('expenses');

    if (expensesJson != null) {
      final List<dynamic> decoded = json.decode(expensesJson);
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // Save expenses to SharedPreferences
  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _expenses.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('expenses', encoded);
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _saveExpenses();
    notifyListeners();
  }

  Future<void> editExpense(Expense updatedExpense) async {
    final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      await _saveExpenses();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpenses();
    notifyListeners();
  }

  // Get expenses for current month only
  List<Expense> getCurrentMonthExpenses() {
    final now = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  // Get expenses for a specific month/year
  List<Expense> getExpensesByMonth(int year, int month) {
    return _expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }

  // Get all historical expenses (for reports)
  List<Expense> getAllExpenses() {
    return List.unmodifiable(_expenses);
  }

  // Clear only current month expenses (if needed for testing)
  Future<void> clearCurrentMonthExpenses() async {
    final now = DateTime.now();
    _expenses.removeWhere((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    });
    await _saveExpenses();
    notifyListeners();
  }

  // DO NOT USE THIS - Only for complete data wipe
  Future<void> clearAllExpenses() async {
    _expenses.clear();
    await _saveExpenses();
    notifyListeners();
  }
}
