import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> wakeUp(String stopName) async {
    await init();
    await _plugin.show(
      id: 1001,
      title: 'Sắp tới trạm $stopName',
      body: 'Chuẩn bị xuống xe nhé! Nhấn để mở ứng dụng.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_alarm',
          'Báo thức xuống trạm',
          channelDescription: 'Báo khi sắp tới trạm cần xuống',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true, interruptionLevel: InterruptionLevel.timeSensitive),
      ),
    );
  }
}
