import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'supabase_service.dart';

class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  final _supabase = SupabaseService().client;

  /// Sync budget to Supabase
  Future<void> syncBudget({
    required double totalBudget,
    required double foodsLimit,
    required double transportationLimit,
    required double shoppingLimit,
    required double billsLimit,
    required int month,
    required int year,
  }) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('budgets').upsert({
        'user_id': userId,
        'total_budget': totalBudget,
        'foods_limit': foodsLimit,
        'transportation_limit': transportationLimit,
        'shopping_limit': shoppingLimit,
        'bills_limit': billsLimit,
        'month': month,
        'year': year,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,month,year');

      debugPrint('✅ Budget synced to Supabase');
    } catch (e) {
      debugPrint('❌ Error syncing budget: $e');
      rethrow;
    }
  }

  /// Load budget from Supabase for specific month/year
  Future<Map<String, double>?> loadBudget(int month, int year) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // ADDED: Debug logging
      debugPrint(
        '🔍 Loading budget for user: $userId, month: $month, year: $year',
      );

      final response = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      // ADDED: Debug logging
      debugPrint('🔍 Supabase response: $response');

      if (response == null) {
        debugPrint('⚠️ No budget found in Supabase'); // ADDED
        return null;
      }

      debugPrint('✅ Budget found: ₱${response['total_budget']}'); // ADDED

      return {
        'total_budget': (response['total_budget'] as num).toDouble(),
        'foods_limit': (response['foods_limit'] as num).toDouble(),
        'transportation_limit': (response['transportation_limit'] as num)
            .toDouble(),
        'shopping_limit': (response['shopping_limit'] as num).toDouble(),
        'bills_limit': (response['bills_limit'] as num).toDouble(),
      };
    } catch (e) {
      debugPrint('❌ Error loading budget: $e');
      return null;
    }
  }

  /// Load the most recent budget (any month/year)
  Future<Map<String, double>?> loadLatestBudget() async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('🔍 Loading latest budget for user: $userId');

      final response = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false)
          .order('month', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('🔍 Latest budget response: $response');

      if (response == null) {
        debugPrint('⚠️ No budget found in Supabase');
        return null;
      }

      debugPrint(
        '✅ Latest budget found: ₱${response['total_budget']} from ${response['month']}/${response['year']}',
      );

      return {
        'total_budget': (response['total_budget'] as num).toDouble(),
        'foods_limit': (response['foods_limit'] as num).toDouble(),
        'transportation_limit': (response['transportation_limit'] as num)
            .toDouble(),
        'shopping_limit': (response['shopping_limit'] as num).toDouble(),
        'bills_limit': (response['bills_limit'] as num).toDouble(),
      };
    } catch (e) {
      debugPrint('❌ Error loading latest budget: $e');
      return null;
    }
  }

  /// Sync single expense to Supabase
  Future<void> syncExpense(Expense expense) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('expenses').upsert({
        'id': expense.id,
        'user_id': userId,
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'note': expense.note,
        'date': expense.date.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Expense synced: ${expense.category} - ₱${expense.amount}');
    } catch (e) {
      debugPrint('❌ Error syncing expense: $e');
      rethrow;
    }
  }

  /// Sync all expenses to Supabase
  Future<void> syncAllExpenses(List<Expense> expenses) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      for (var expense in expenses) {
        await syncExpense(expense);
      }

      debugPrint('✅ All expenses synced (${expenses.length} items)');
    } catch (e) {
      debugPrint('❌ Error syncing all expenses: $e');
      rethrow;
    }
  }

  /// Load all expenses from Supabase
  Future<List<Expense>> loadAllExpenses() async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      final expenses = (response as List).map((data) {
        return Expense(
          id: data['id'],
          title: data['title'] ?? 'Expense',
          amount: (data['amount'] as num).toDouble(),
          category: data['category'],
          note: data['note'] ?? '',
          date: DateTime.parse(data['date']),
        );
      }).toList();

      debugPrint('✅ Loaded ${expenses.length} expenses from Supabase');
      return expenses;
    } catch (e) {
      debugPrint('❌ Error loading expenses: $e');
      return [];
    }
  }

  /// Load expenses for specific month/year
  Future<List<Expense>> loadExpensesByMonth(int year, int month) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      final expenses = (response as List).map((data) {
        return Expense(
          id: data['id'],
          title: data['title'] ?? 'Expense',
          amount: (data['amount'] as num).toDouble(),
          category: data['category'],
          note: data['note'] ?? '',
          date: DateTime.parse(data['date']),
        );
      }).toList();

      debugPrint('✅ Loaded ${expenses.length} expenses for $month/$year');
      return expenses;
    } catch (e) {
      debugPrint('❌ Error loading expenses by month: $e');
      return [];
    }
  }

  /// Delete expense from Supabase
  Future<void> deleteExpense(String expenseId) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', userId);

      debugPrint('✅ Expense deleted from Supabase');
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
      rethrow;
    }
  }

  /// Sync user preferences to Supabase
  Future<void> syncPreferences({
    required bool isDarkMode,
    required String language,
    required bool pushNotifications,
    required bool budgetAlerts,
  }) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'is_dark_mode': isDarkMode,
        'language': language,
        'push_notifications': pushNotifications,
        'budget_alerts': budgetAlerts,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Preferences synced to Supabase');
    } catch (e) {
      debugPrint('❌ Error syncing preferences: $e');
      rethrow;
    }
  }

  /// Load user preferences from Supabase
  Future<Map<String, dynamic>?> loadPreferences() async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      debugPrint('✅ Preferences loaded from Supabase');
      return response;
    } catch (e) {
      debugPrint('❌ Error loading preferences: $e');
      return null;
    }
  }

  /// Delete current month data only (for reset functionality)
  Future<void> deleteCurrentMonthData() async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      debugPrint('🔵 Deleting current month data: ${now.month}/${now.year}');

      // Delete current month expenses
      final expensesDeleted = await _supabase
          .from('expenses')
          .delete()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      debugPrint('✅ Current month expenses deleted from Supabase');

      // Delete current month budget
      await deleteCurrentMonthBudget(now.month, now.year);

      debugPrint('✅ Current month data deleted from Supabase');
    } catch (e) {
      debugPrint('❌ Error deleting current month data: $e');
      rethrow;
    }
  }

  /// Delete budget for specific month/year
  Future<void> deleteCurrentMonthBudget(int month, int year) async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('🔵 Deleting budget for $month/$year');

      await _supabase
          .from('budgets')
          .delete()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year);

      debugPrint('✅ Budget for $month/$year deleted from Supabase');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  /// Get all unique custom categories (historical)
  Future<List<String>> getCustomCategories() async {
    try {
      final userId = SupabaseService().currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expenses')
          .select('category')
          .eq('user_id', userId);

      final predefinedCategories = [
        'foods',
        'food',
        'transportation',
        'transport',
        'shopping',
        'bills',
        'housing',
      ];

      final categories = <String>{};
      for (var item in response as List) {
        final category = item['category'] as String;
        if (!predefinedCategories.contains(category.toLowerCase())) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('❌ Error getting custom categories: $e');
      return [];
    }
  }
}
