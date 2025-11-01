import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  Future<void> scheduleWateringReminder({
    required int plantId,
    required String plantName,
    required DateTime wateringTime,
    required int daysFrequency,
  }) async {
    await _notifications.zonedSchedule(
      plantId,
      '💧 Пора полить растение!',
      'Не забудьте полить $plantName',
      tz.TZDateTime.from(wateringTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel',
          'Напоминания о поливе',
          channelDescription: 'Уведомления о необходимости полива растений',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          badgeNumber: 1,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int plantId) async {
    await _notifications.cancel(plantId);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // УДАЛЯЕМ метод requestPermissions - он не нужен без permission_handler
}