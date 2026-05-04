// Stub file cho các nền tảng không hỗ trợ flutter_local_notifications
// (Web, Windows, Linux, macOS)
// File này cung cấp các class rỗng để tránh lỗi compile

class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(dynamic settings, {dynamic onDidReceiveNotificationResponse}) async => null;
  Future<void> show(int id, String? title, String? body, dynamic notificationDetails, {String? payload}) async {}
  dynamic resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidInitializationSettings {
  const AndroidInitializationSettings(String defaultIcon);
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings();
}

class InitializationSettings {
  const InitializationSettings({dynamic android, dynamic iOS, dynamic macOS, dynamic linux});
}

class AndroidNotificationChannel {
  final String id;
  final String name;
  final String? description;
  final dynamic importance;
  const AndroidNotificationChannel(this.id, this.name, {this.description, this.importance});
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<void> createNotificationChannel(AndroidNotificationChannel channel) async {}
}

class NotificationDetails {
  const NotificationDetails({dynamic android, dynamic iOS});
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(String channelId, String channelName, {String? channelDescription, String? icon, dynamic importance, dynamic priority});
}

class Importance {
  static const Importance max = Importance._();
  const Importance._();
}

class Priority {
  static const Priority high = Priority._();
  const Priority._();
}
