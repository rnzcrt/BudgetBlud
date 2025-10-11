import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/supabase_sync_service.dart';

class BudgetProvider extends ChangeNotifier {
  double _totalBudget = 0.0;

  // Category limits
  double _foodsLimit = 0.0;
  double _transportationLimit = 0.0;
  double _shoppingLimit = 0.0;
  double _billsLimit = 0.0;

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  bool _isLoaded = false;

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

    debugPrint('🔵 Loaded budget from local: ₱$_totalBudget');

    // Load from Supabase if authenticated
    if (SupabaseService().isAuthenticated) {
      try {
        final syncService = SupabaseSyncService();
        final supabaseBudget = await syncService.loadBudget(_month, _year);
        if (supabaseBudget != null) {
          _totalBudget = supabaseBudget['total_budget']!;
          _foodsLimit = supabaseBudget['foods_limit']!;
          _transportationLimit = supabaseBudget['transportation_limit']!;
          _shoppingLimit = supabaseBudget['shopping_limit']!;
          _billsLimit = supabaseBudget['bills_limit']!;

          debugPrint('✅ Loaded budget from Supabase: ₱$_totalBudget');

          // Update local storage
          await prefs.setDouble('total_budget', _totalBudget);
          await prefs.setDouble('foods_limit', _foodsLimit);
          await prefs.setDouble('transportation_limit', _transportationLimit);
          await prefs.setDouble('shopping_limit', _shoppingLimit);
          await prefs.setDouble('bills_limit', _billsLimit);
        }
      } catch (e) {
        debugPrint('❌ Error loading budget from Supabase: $e');
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setBudget(double amount) async {
    _totalBudget = amount;
    _isLoaded = true;

    debugPrint('🔵 Setting budget: ₱$amount');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget', amount);

    // Sync to Supabase
    if (SupabaseService().isAuthenticated) {
      try {
        await SupabaseSyncService().syncBudget(
          totalBudget: _totalBudget,
          foodsLimit: _foodsLimit,
          transportationLimit: _transportationLimit,
          shoppingLimit: _shoppingLimit,
          billsLimit: _billsLimit,
          month: _month,
          year: _year,
        );
        debugPrint('✅ Budget synced to Supabase');
      } catch (e) {
        debugPrint('❌ Failed to sync budget to Supabase: $e');
      }
    }

    notifyListeners();
  }

  Future<void> reloadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _totalBudget = prefs.getDouble('total_budget') ?? 0.0;
    _foodsLimit = prefs.getDouble('foods_limit') ?? 0.0;
    _transportationLimit = prefs.getDouble('transportation_limit') ?? 0.0;
    _shoppingLimit = prefs.getDouble('shopping_limit') ?? 0.0;
    _billsLimit = prefs.getDouble('bills_limit') ?? 0.0;
    _isLoaded = true;

    debugPrint('🔵 Reloaded budget: ₱$_totalBudget');
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

    debugPrint(
      '🔵 Setting category limits: F=₱$foods, T=₱$transportation, S=₱$shopping, B=₱$bills',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('foods_limit', foods);
    await prefs.setDouble('transportation_limit', transportation);
    await prefs.setDouble('shopping_limit', shopping);
    await prefs.setDouble('bills_limit', bills);

    // Sync to Supabase
    if (SupabaseService().isAuthenticated) {
      try {
        await SupabaseSyncService().syncBudget(
          totalBudget: _totalBudget,
          foodsLimit: _foodsLimit,
          transportationLimit: _transportationLimit,
          shoppingLimit: _shoppingLimit,
          billsLimit: _billsLimit,
          month: _month,
          year: _year,
        );
        debugPrint('✅ Category limits synced to Supabase');
      } catch (e) {
        debugPrint('❌ Failed to sync category limits to Supabase: $e');
      }
    }

    notifyListeners();
  }

  double get totalCategoryLimits =>
      _foodsLimit + _transportationLimit + _shoppingLimit + _billsLimit;

  double get remainingBudget => _totalBudget - totalCategoryLimits;

  /// Reset ONLY current month budget (for Reset App Data feature)
  /// This does NOT delete historical budget data from Supabase
  Future<void> resetBudget() async {
    debugPrint('🔵 Resetting current month budget ($_month/$_year)');

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

    debugPrint('✅ Local budget cleared');

    // Delete ONLY current month from Supabase (keeps historical data)
    if (SupabaseService().isAuthenticated) {
      try {
        await SupabaseSyncService().deleteCurrentMonthBudget(_month, _year);
        debugPrint('✅ Current month budget deleted from Supabase');
      } catch (e) {
        debugPrint('❌ Failed to delete budget from Supabase: $e');
      }
    }

    notifyListeners();
  }
}
