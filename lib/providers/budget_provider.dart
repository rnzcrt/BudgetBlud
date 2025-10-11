import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetProvider extends ChangeNotifier {
  double _totalBudget = 0.0;

  // Category limits
  double _foodsLimit = 0.0;
  double _transportationLimit = 0.0;
  double _shoppingLimit = 0.0;
  double _billsLimit = 0.0;

  bool _isLoaded = false; // Add flag to track if data is loaded

  double get totalBudget => _totalBudget;
  double get foodsLimit => _foodsLimit;
  double get transportationLimit => _transportationLimit;
  double get shoppingLimit => _shoppingLimit;
  double get billsLimit => _billsLimit;
  bool get isLoaded => _isLoaded;

  BudgetProvider() {
    _loadBudget();
  }

  // Load budget from SharedPreferences
  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _totalBudget = prefs.getDouble('total_budget') ?? 0.0;
    _foodsLimit = prefs.getDouble('foods_limit') ?? 0.0;
    _transportationLimit = prefs.getDouble('transportation_limit') ?? 0.0;
    _shoppingLimit = prefs.getDouble('shopping_limit') ?? 0.0;
    _billsLimit = prefs.getDouble('bills_limit') ?? 0.0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setBudget(double amount) async {
    _totalBudget = amount;
    _isLoaded = true; // Mark as loaded since we're setting it manually
    // Removed notifyListeners() before saving

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget', amount);

    notifyListeners(); // Notify AFTER saving to be safe
  }

  Future<void> reloadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _totalBudget = prefs.getDouble('total_budget') ?? 0.0;
    _foodsLimit = prefs.getDouble('foods_limit') ?? 0.0;
    _transportationLimit = prefs.getDouble('transportation_limit') ?? 0.0;
    _shoppingLimit = prefs.getDouble('shopping_limit') ?? 0.0;
    _billsLimit = prefs.getDouble('bills_limit') ?? 0.0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setCategoryLimits({
    required double foods,
    required double transportation,
    required double shopping,
    required double bills,
  }) async {
    _foodsLimit = foods;
    _transportationLimit = transportation;
    _shoppingLimit = shopping;
    _billsLimit = bills;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('foods_limit', foods);
    await prefs.setDouble('transportation_limit', transportation);
    await prefs.setDouble('shopping_limit', shopping);
    await prefs.setDouble('bills_limit', bills);

    notifyListeners();
  }

  double get totalCategoryLimits =>
      _foodsLimit + _transportationLimit + _shoppingLimit + _billsLimit;

  double get remainingBudget => _totalBudget - totalCategoryLimits;

  // Reset only current month budget (for monthly renewal)
  // This does NOT delete historical data
  Future<void> resetBudget() async {
    _totalBudget = 0;
    _foodsLimit = 0;
    _transportationLimit = 0;
    _shoppingLimit = 0;
    _billsLimit = 0;
    _isLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_budget');
    await prefs.remove('foods_limit');
    await prefs.remove('transportation_limit');
    await prefs.remove('shopping_limit');
    await prefs.remove('bills_limit');

    notifyListeners();
  }
}
