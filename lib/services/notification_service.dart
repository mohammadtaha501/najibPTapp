import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:untitled3/main.dart'; // To access navigatorKey

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("SYSTEM: Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Simulates a persistent state for scheduled reminders
  static final Set<String> _pendingReminders = {};

  static Future<void> initialize() async {
    // 1. Initialize Local Notifications for Foreground Alerts
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification click
        print("SYSTEM: Local Notification Clicked: ${response.payload}");
      }
    );

    // 2. Clear Badges on Start
    await resetBadge();

    // 3. Configure FCM Foreground Presentation (iOS specific)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          payload: message.data['type'] ?? '',
        );
      }
    });

    // 6. Handle notification when app is in background but NOT terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("SYSTEM: App opened from background via notification tap");
      _handleNotificationClick(message);
    });

    // 7. Handle notification when app is opened from TERMINATED state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("SYSTEM: App opened from terminated state via notification tap");
      _handleNotificationClick(initialMessage);
    }
  }

  static void _handleNotificationClick(RemoteMessage message) {
    // Example navigation logic
    // String? type = message.data['type'];
    // if (type == 'chat') {
    //   MyApp.navigatorKey.currentState?.pushNamed('/chat', arguments: message.data['senderId']);
    // }
    print("TODO: Implement specific navigation for payload: ${message.data}");
  }

  static Future<void> resetBadge() async {
      try {
        if (await FlutterAppBadger.isAppBadgeSupported()) {
          FlutterAppBadger.removeBadge();
          print('SYSTEM: Badge removed');
        }
      } catch (e) {
        print('Error resetting badge: $e');
      }
  }

  static Future<void> showLocalNotification(String title, String body, {String? payload}) async {
    print('PUSH NOTIFICATION: [$title] $body');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  static void scheduleWorkoutReminder(String clientId, String programName, int day) {
    final key = '$clientId-$programName-$day';
    _pendingReminders.add(key);
    print('SYSTEM: Scheduled reminder for $clientId: "Don\'t forget Day $day of $programName!"');
  }

  static void cancelWorkoutReminder(String clientId, String programName, int day) {
    final key = '$clientId-$programName-$day';
    if (_pendingReminders.remove(key)) {
      print('SYSTEM: Automatically cancelled reminder for $clientId for today.');
    }
  }

  static void notifyCoachOfCompletion(String coachId, String clientName, String programName) {
    showLocalNotification('Workout Completed!', '$clientName just finished a session in $programName.');
  }

  static void notifyCoachOfMissedWorkout(String coachId, String clientName) {
    showLocalNotification('Missed Workout!', '$clientName has not logged any activity for their scheduled session.');
  }

  static void handleIncomingMessage(String senderName, String message) {
    showLocalNotification('New Message from $senderName', message);
  }

  static void notifyProgramCompletion(String coachId, String clientName, String programName) {
    showLocalNotification('Program Completed! 🎉', '$clientName has successfully finished the program: $programName. Reach out to congratulate them!');
  }

  static void notifyClientOfProgramUpdate(String clientId, String programName) {
    showLocalNotification('Program Updated', 'Your coach has updated $programName. Check your dashboard for changes.');
  }

  static void notifyClientOfNutritionUpdate(String clientId) {
    showLocalNotification('Nutrition Updated', 'Your coach updated your nutrition plan.');
  }
}
