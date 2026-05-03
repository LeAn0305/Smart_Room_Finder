import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initFCM() async {
    // Không hỗ trợ Windows/Desktop, tránh lỗi FlutterLocalNotificationsPlugin
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      // 1. Cấu hình Local Notifications để nhận thông báo khi app đang mở (Foreground)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Cấu hình Channel cho Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 2. Lắng nghe FCM Token và lưu lên Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Lấy token hiện tại
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _saveTokenToFirestore(user.uid, token);
        }

        // Lắng nghe token bị thay đổi
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(user.uid, newToken);
        });
      }

      // 3. Lắng nghe thông báo khi app đang chạy (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo FCM: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint('Không thể lưu FCM Token: $e');
    }
  }
}
