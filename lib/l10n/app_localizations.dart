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
      // Navigation
      'dashboard': 'Dashboard',
      'budget': 'Budget',
      'reports': 'Reports',
      'expenses': 'Expenses',
      'transactions': 'Transactions',
      'overview': 'Overview',
      'settings': 'Settings',

      // Reports
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

      // Settings
      'app_settings': 'App Settings',
      'preferences': 'Preferences',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'data_management': 'Data Management',
      'reset_app_data': 'Reset App Data',
      'export_data': 'Export Data',
      'about': 'About',
      'version': 'Version',

      // Categories
      'foods': 'Foods',
      'transportation': 'Transportation',
      'shopping': 'Shopping',
      'bills': 'Bills',

      // Common
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'add': 'Add',
      'next': 'Next',
      'back': 'Back',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
    },
    'tl': {
      // Navigation
      'dashboard': 'Dashboard',
      'budget': 'Badyet',
      'reports': 'Mga Ulat',
      'expenses': 'Mga Gastos',
      'transactions': 'Mga Transaksyon',
      'overview': 'Pangkalahatang Ideya',
      'settings': 'Mga Setting',

      // Reports
      'spending_by_category': 'Paggastos ayon sa Kategorya',
      'monthly_spending_trends': 'Buwanang Paggastos',
      'this_month': 'Ngayong Buwan',
      'last_6_months': 'Huling 6 na Buwan',
      'comparison': 'Paghahambing',
      'this_month_vs_last': 'Ngayong Buwan vs. Nakaraang Buwan',
      'total_spending': 'Kabuuang Gastos',
      'remaining': 'Natitira',
      'spent': 'Ginastos',
      'left': 'Natitira',
      'exceeded': 'Lumampas',

      // Settings
      'app_settings': 'Mga Setting ng App',
      'preferences': 'Mga Kagustuhan',
      'language': 'Wika',
      'theme': 'Tema',
      'dark_mode': 'Madilim na Mode',
      'light_mode': 'Maliwanag na Mode',
      'data_management': 'Pamamahala ng Data',
      'reset_app_data': 'I-reset ang Data ng App',
      'export_data': 'I-export ang Data',
      'about': 'Tungkol sa App',
      'version': 'Bersyon',

      // Categories
      'foods': 'Pagkain',
      'transportation': 'Transportasyon',
      'shopping': 'Pamimili',
      'bills': 'Mga Bayarin',

      // Common
      'cancel': 'Kanselahin',
      'confirm': 'Kumpirmahin',
      'save': 'I-save',
      'edit': 'I-edit',
      'delete': 'Tanggalin',
      'add': 'Magdagdag',
      'next': 'Susunod',
      'back': 'Bumalik',
      'done': 'Tapos na',
      'yes': 'Oo',
      'no': 'Hindi',
    },
    'es': {
      // Navigation
      'dashboard': 'Panel',
      'budget': 'Presupuesto',
      'reports': 'Informes',
      'expenses': 'Gastos',
      'transactions': 'Transacciones',
      'overview': 'Resumen',
      'settings': 'Configuración',

      // Reports
      'spending_by_category': 'Gastos por Categoría',
      'monthly_spending_trends': 'Tendencias Mensuales de Gastos',
      'this_month': 'Este Mes',
      'last_6_months': 'Últimos 6 Meses',
      'comparison': 'Comparación',
      'this_month_vs_last': 'Este Mes vs. Mes Anterior',
      'total_spending': 'Gasto Total',
      'remaining': 'Restante',
      'spent': 'Gastado',
      'left': 'Disponible',
      'exceeded': 'Excedido',

      // Settings
      'app_settings': 'Configuración de la Aplicación',
      'preferences': 'Preferencias',
      'language': 'Idioma',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'data_management': 'Gestión de Datos',
      'reset_app_data': 'Restablecer Datos de la Aplicación',
      'export_data': 'Exportar Datos',
      'about': 'Acerca de',
      'version': 'Versión',

      // Categories
      'foods': 'Alimentos',
      'transportation': 'Transporte',
      'shopping': 'Compras',
      'bills': 'Facturas',

      // Common
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'save': 'Guardar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'add': 'Agregar',
      'next': 'Siguiente',
      'back': 'Atrás',
      'done': 'Hecho',
      'yes': 'Sí',
      'no': 'No',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters - Navigation
  String get dashboard => translate('dashboard');
  String get budget => translate('budget');
  String get reports => translate('reports');
  String get expenses => translate('expenses');
  String get transactions => translate('transactions');
  String get overview => translate('overview');
  String get settings => translate('settings');

  // Reports
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

  // Settings
  String get appSettings => translate('app_settings');
  String get preferences => translate('preferences');
  String get language => translate('language');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get dataManagement => translate('data_management');
  String get resetAppData => translate('reset_app_data');
  String get exportData => translate('export_data');
  String get about => translate('about');
  String get version => translate('version');

  // Categories
  String get foods => translate('foods');
  String get transportation => translate('transportation');
  String get shopping => translate('shopping');
  String get bills => translate('bills');

  // Common
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get add => translate('add');
  String get next => translate('next');
  String get back => translate('back');
  String get done => translate('done');
  String get yes => translate('yes');
  String get no => translate('no');
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
