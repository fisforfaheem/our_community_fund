import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/models/user_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  NotificationService(this._prefs);

  static Future<NotificationService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationService(prefs);
  }

  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _prefs.setString('fcm_token', token);
          if (kDebugMode) {
            print('FCM Token: $token');
          }
        }

        // Handle token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          await _prefs.setString('fcm_token', newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print(
                'Received foreground message: ${message.notification?.title}');
          }
          // Handle the message display here
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) throw Exception('User has no FCM token');

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send to Firebase Cloud Messaging
      await _firestore.collection('fcm').add({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      try {
        await sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      } catch (e) {
        print('Failed to send notification to user $userId: $e');
      }
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      if (data != null) ...data,
    });
  }

  Future<void> sendPaymentConfirmation(UserModel user, double amount) async {
    await _sendNotification(
      title: 'Payment Received',
      body: 'Thank you for your payment of \$${amount.toStringAsFixed(2)}',
      userId: user.id,
    );
  }

  Future<void> sendExtraContributionConfirmation(
      UserModel user, double amount) async {
    await _sendNotification(
      title: 'Extra Contribution Received',
      body:
          'Thank you for your extra contribution of \$${amount.toStringAsFixed(2)}',
      userId: user.id,
    );
  }

  Future<void> sendOverdueNotification(UserModel user) async {
    await sendNotificationToUser(
      userId: user.id,
      title: 'Payment Overdue',
      body:
          'Your community fund payment for this month is overdue. Please make your payment soon.',
      data: {
        'type': 'payment_overdue',
        'userId': user.id,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
              'timestamp': doc.data()['timestamp']?.toDate(),
            })
        .toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> updateNotificationPreferences({
    required bool paymentReminders,
    required bool paymentConfirmations,
    required bool systemUpdates,
  }) async {
    if (paymentReminders) {
      await subscribeToTopic('payment_reminders');
    } else {
      await unsubscribeFromTopic('payment_reminders');
    }

    if (paymentConfirmations) {
      await subscribeToTopic('payment_confirmations');
    } else {
      await unsubscribeFromTopic('payment_confirmations');
    }

    if (systemUpdates) {
      await subscribeToTopic('system_updates');
    } else {
      await unsubscribeFromTopic('system_updates');
    }

    await _prefs.setBool('notify_payment_reminders', paymentReminders);
    await _prefs.setBool('notify_payment_confirmations', paymentConfirmations);
    await _prefs.setBool('notify_system_updates', systemUpdates);
  }

  bool get paymentRemindersEnabled =>
      _prefs.getBool('notify_payment_reminders') ?? true;

  bool get paymentConfirmationsEnabled =>
      _prefs.getBool('notify_payment_confirmations') ?? true;

  bool get systemUpdatesEnabled =>
      _prefs.getBool('notify_system_updates') ?? true;

  Future<void> scheduleMonthlyReminder(UserModel user) async {
    if (!paymentRemindersEnabled) return;

    final now = DateTime.now();
    final settings =
        await _firestore.collection('settings').doc('payments').get();
    final reminderDay = settings.data()?['reminderDay'] ?? 25;

    var reminderDate = DateTime(now.year, now.month, reminderDay);
    if (now.day >= reminderDay) {
      reminderDate = DateTime(now.year, now.month + 1, reminderDay);
    }

    await _firestore.collection('scheduled_notifications').add({
      'userId': user.id,
      'type': 'payment_reminder',
      'scheduledFor': reminderDate,
      'title': 'Payment Reminder',
      'body': 'Your monthly payment is due soon.',
      'created': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
  // Add any background message handling logic here
}
