import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'dashboard': 'Dashboard',
      'budget': 'Budget',
      'reports': 'Reports',
      'expenses': 'Expenses',
      'transactions': 'Transactions',
      'overview': 'Overview',
      'settings': 'Settings',
      'spending_by_category': 'Spending by Category',
      'monthly_spending_trends': 'Monthly Spending Trends',
      'this_month': 'This Month',
      'last_6_months': 'Last 6 Months',
      'comparison': 'Comparison',
      'this_month_vs_last': 'This Month vs. Last Month',
      'total_spending': 'Total Spending',
      'remaining': 'Remaining',
      'spent': 'spent',
      'left': 'Left',
      'exceeded': 'Exceeded',
    },
    'tl': {
      'dashboard': 'Dashboard',
      'budget': 'Badyet',
      'reports': 'Mga Ulat',
      'expenses': 'Mga Gastos',
      'transactions': 'Mga Transaksyon',
      'overview': 'Pangkalahatang-ideya',
      'settings': 'Mga Setting',
      'spending_by_category': 'Paggastos ayon sa Kategorya',
      'monthly_spending_trends': 'Tuwing Buwan na Paggastos',
      'this_month': 'Ngayong Buwan',
      'last_6_months': 'Nakaraang 6 na Buwan',
      'comparison': 'Paghahambing',
      'this_month_vs_last': 'Ngayong Buwan vs. Nakaraang Buwan',
      'total_spending': 'Kabuuang Gastos',
      'remaining': 'Natitira',
      'spent': 'nagastos',
      'left': 'Natitira',
      'exceeded': 'Lumampas',
    },
    'es': {
      'dashboard': 'Panel',
      'budget': 'Presupuesto',
      'reports': 'Informes',
      'expenses': 'Gastos',
      'transactions': 'Transacciones',
      'overview': 'Resumen',
      'settings': 'Configuración',
      'spending_by_category': 'Gastos por Categoría',
      'monthly_spending_trends': 'Tendencias Mensuales de Gastos',
      'this_month': 'Este Mes',
      'last_6_months': 'Últimos 6 Meses',
      'comparison': 'Comparación',
      'this_month_vs_last': 'Este Mes vs. Mes Anterior',
      'total_spending': 'Gasto Total',
      'remaining': 'Restante',
      'spent': 'gastado',
      'left': 'Restante',
      'exceeded': 'Excedido',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get dashboard => translate('dashboard');
  String get budget => translate('budget');
  String get reports => translate('reports');
  String get expenses => translate('expenses');
  String get transactions => translate('transactions');
  String get overview => translate('overview');
  String get settings => translate('settings');
  String get spendingByCategory => translate('spending_by_category');
  String get monthlySpendingTrends => translate('monthly_spending_trends');
  String get thisMonth => translate('this_month');
  String get last6Months => translate('last_6_months');
  String get comparison => translate('comparison');
  String get thisMonthVsLast => translate('this_month_vs_last');
  String get totalSpending => translate('total_spending');
  String get remaining => translate('remaining');
  String get spent => translate('spent');
  String get left => translate('left');
  String get exceeded => translate('exceeded');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tl', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
