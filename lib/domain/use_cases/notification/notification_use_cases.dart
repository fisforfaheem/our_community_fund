import 'package:our_community_fund/domain/repositories/notification_repository.dart';

class WatchNotificationsUseCase {
  final NotificationRepository _repository;
  WatchNotificationsUseCase(this._repository);
  Stream<List<Map<String, dynamic>>> execute(String userId) =>
      _repository.watchNotifications(userId);
}

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;
  MarkNotificationReadUseCase(this._repository);
  Future<void> execute(String notificationId) =>
      _repository.markAsRead(notificationId);
}

class MarkAllNotificationsReadUseCase {
  final NotificationRepository _repository;
  MarkAllNotificationsReadUseCase(this._repository);
  Future<void> execute(String userId) => _repository.markAllAsRead(userId);
}
