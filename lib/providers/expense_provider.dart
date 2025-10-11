import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';
import '../services/supabase_sync_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isSyncing = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isSyncing => _isSyncing;

  ExpenseProvider() {
    _initialize();
  }

  /// Initialize: Load from local first, then sync with Supabase
  Future<void> _initialize() async {
    await _loadExpensesLocal();
    await syncFromSupabase();
  }

  /// Load expenses from SharedPreferences (local cache)
  Future<void> _loadExpensesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('expenses');

    if (expensesJson != null) {
      final List<dynamic> decoded = json.decode(expensesJson);
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
      notifyListeners();
    }
  }

  /// Save expenses to SharedPreferences (local cache)
  Future<void> _saveExpensesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _expenses.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('expenses', encoded);
  }

  /// Sync FROM Supabase (download all expenses)
  Future<void> syncFromSupabase() async {
    if (!SupabaseService().isAuthenticated) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final syncService = SupabaseSyncService();
      final supabaseExpenses = await syncService.loadAllExpenses();

      // Merge with local data (Supabase is source of truth)
      _expenses = supabaseExpenses;
      await _saveExpensesLocal();

      debugPrint('✅ Synced ${_expenses.length} expenses from Supabase');
    } catch (e) {
      debugPrint('❌ Error syncing from Supabase: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Add expense (save locally + sync to Supabase)
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _saveExpensesLocal();
    notifyListeners();

    // Sync to Supabase in background
    if (SupabaseService().isAuthenticated) {
      try {
        await SupabaseSyncService().syncExpense(expense);
      } catch (e) {
        debugPrint('❌ Failed to sync expense to Supabase: $e');
      }
    }
  }

  /// Edit expense (save locally + sync to Supabase)
  Future<void> editExpense(Expense updatedExpense) async {
    final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      await _saveExpensesLocal();
      notifyListeners();

      // Sync to Supabase in background
      if (SupabaseService().isAuthenticated) {
        try {
          await SupabaseSyncService().syncExpense(updatedExpense);
        } catch (e) {
          debugPrint('❌ Failed to sync updated expense to Supabase: $e');
        }
      }
    }
  }

  /// Delete expense (remove locally + sync to Supabase)
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpensesLocal();
    notifyListeners();

    // Sync deletion to Supabase in background
    if (SupabaseService().isAuthenticated) {
      try {
        await SupabaseSyncService().deleteExpense(id);
      } catch (e) {
        debugPrint('❌ Failed to delete expense from Supabase: $e');
      }
    }
  }

  /// Get expenses for current month only
  List<Expense> getCurrentMonthExpenses() {
    final now = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  /// Get expenses for a specific month/year
  List<Expense> getExpensesByMonth(int year, int month) {
    return _expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }

  /// Get all historical expenses (for reports)
  List<Expense> getAllExpenses() {
    return List.unmodifiable(_expenses);
  }

  /// Get all unique custom categories (case-insensitive, properly capitalized)
  List<String> getCustomCategories() {
    final predefinedCategories = [
      'foods',
      'food',
      'transportation',
      'transport',
      'shopping',
      'bills',
      'housing',
    ];

    Map<String, String> categoryMap = {};

    for (var expense in _expenses) {
      final category = expense.category;
      final normalizedCategory = category.toLowerCase();

      if (predefinedCategories.contains(normalizedCategory)) {
        continue;
      }

      if (!categoryMap.containsKey(normalizedCategory)) {
        final properCase = category.isNotEmpty
            ? category[0].toUpperCase() + category.substring(1).toLowerCase()
            : category;
        categoryMap[normalizedCategory] = properCase;
      }
    }

    return categoryMap.values.toList()..sort();
  }

  /// Get custom categories for current month only
  List<String> getCurrentMonthCustomCategories() {
    final predefinedCategories = [
      'foods',
      'food',
      'transportation',
      'transport',
      'shopping',
      'bills',
      'housing',
    ];

    final now = DateTime.now();
    final currentMonthExpenses = _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    });

    Map<String, String> categoryMap = {};

    for (var expense in currentMonthExpenses) {
      final category = expense.category;
      final normalizedCategory = category.toLowerCase();

      if (predefinedCategories.contains(normalizedCategory)) {
        continue;
      }

      if (!categoryMap.containsKey(normalizedCategory)) {
        final properCase = category.isNotEmpty
            ? category[0].toUpperCase() + category.substring(1).toLowerCase()
            : category;
        categoryMap[normalizedCategory] = properCase;
      }
    }

    return categoryMap.values.toList()..sort();
  }

  /// Clear ONLY current month expenses (local + Supabase)
  /// Used for "Reset App Data" - preserves historical data
  Future<void> clearCurrentMonthExpenses() async {
    final now = DateTime.now();

    debugPrint('🔵 Clearing current month expenses (${now.month}/${now.year})');

    // Get IDs of current month expenses before removing
    final currentMonthExpenseIds = _expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .map((e) => e.id)
        .toList();

    debugPrint('🔵 Found ${currentMonthExpenseIds.length} expenses to delete');

    // Remove from local list
    _expenses.removeWhere((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    });

    // Save updated list locally
    await _saveExpensesLocal();
    notifyListeners();

    debugPrint('✅ Local expenses cleared. Remaining: ${_expenses.length}');

    // Remove from Supabase
    if (SupabaseService().isAuthenticated) {
      try {
        final syncService = SupabaseSyncService();

        // Delete current month expenses from Supabase
        await syncService.deleteCurrentMonthData();

        debugPrint('✅ Supabase current month data cleared');
      } catch (e) {
        debugPrint('❌ Failed to clear current month from Supabase: $e');
        // Don't throw - local data is already cleared
      }
    }
  }

  /// DANGER: Clear ALL expenses (local + Supabase)
  /// Only use for complete account deletion or testing
  Future<void> clearAllExpenses() async {
    debugPrint('⚠️ WARNING: Clearing ALL expenses (not just current month)');

    _expenses.clear();
    await _saveExpensesLocal();
    notifyListeners();

    debugPrint('✅ All local expenses cleared');

    // Note: Keeping this commented for safety
    // Uncomment only if you want to delete ALL historical data from Supabase
    /*
    if (SupabaseService().isAuthenticated) {
      final userId = SupabaseService().currentUserId;
      await SupabaseService().client
          .from('expenses')
          .delete()
          .eq('user_id', userId);
      debugPrint('✅ All Supabase expenses deleted');
    }
    */
  }
}
