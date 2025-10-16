import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  /// Check if budget alerts are enabled in settings
  Future<bool> _areBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('budget_alerts_enabled') ?? false;
  }

  /// Show immediate notification for budget threshold
  Future<void> showBudgetAlert({
    required String title,
    required String message,
    required int notificationId,
  }) async {
    // Check if budget alerts are enabled
    if (!await _areBudgetAlertsEnabled()) {
      print('❌ Budget alerts disabled in settings');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget thresholds',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(notificationId, title, message, details);

    print('✅ Notification sent: $title - $message');
  }

  /// Show 80% budget warning
  Future<void> show80PercentWarning(
    double totalSpent,
    double totalBudget,
  ) async {
    final percentage = (totalSpent / totalBudget * 100).toStringAsFixed(0);

    await showBudgetAlert(
      title: '⚠️ Budget Alert',
      message:
          'You\'ve used $percentage% of your budget (₱${totalSpent.toStringAsFixed(0)} / ₱${totalBudget.toStringAsFixed(0)})',
      notificationId: 1,
    );
  }

  /// Show 100% budget exceeded alert
  Future<void> show100PercentAlert(
    double totalSpent,
    double totalBudget,
  ) async {
    final exceeded = totalSpent - totalBudget;

    await showBudgetAlert(
      title: '🚨 Budget Exceeded!',
      message:
          'You\'ve exceeded your budget by ₱${exceeded.toStringAsFixed(0)}',
      notificationId: 2,
    );
  }

  /// Show category budget warning (80%)
  Future<void> showCategoryWarning(
    String category,
    double spent,
    double limit,
  ) async {
    final percentage = (spent / limit * 100).toStringAsFixed(0);

    await showBudgetAlert(
      title: '⚠️ $category Alert',
      message:
          '$percentage% of $category budget used (₱${spent.toStringAsFixed(0)} / ₱${limit.toStringAsFixed(0)})',
      notificationId: 3,
    );
  }

  /// Show category budget exceeded (100%)
  Future<void> showCategoryExceeded(
    String category,
    double spent,
    double limit,
  ) async {
    final exceeded = spent - limit;

    await showBudgetAlert(
      title: '🚨 $category Exceeded!',
      message: '$category budget exceeded by ₱${exceeded.toStringAsFixed(0)}',
      notificationId: 4,
    );
  }

  Future<void> scheduleDailyNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily budget tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0,
      'Budget Reminder',
      'Don\'t forget to track your expenses today!',
      _nextInstanceOf9AM(),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf9AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
