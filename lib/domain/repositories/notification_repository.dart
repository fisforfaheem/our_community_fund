abstract class NotificationRepository {
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
