import 'package:flutter/material.dart';

class BudgetProvider extends ChangeNotifier {
  double _totalBudget = 0.0;

  double get totalBudget => _totalBudget;

  void setBudget(double amount) {
    _totalBudget = amount;
    notifyListeners();
  }
}
