import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:our_community_fund/core/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Handling background message: ${message.messageId}');
  AppLogger.debug('Message notification: ${message.notification?.title}');
}
