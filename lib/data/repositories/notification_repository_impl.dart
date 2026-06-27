import 'package:our_community_fund/data/datasources/notification_remote_data_source.dart';
import 'package:our_community_fund/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  NotificationRepositoryImpl({required NotificationRemoteDataSource remote})
      : _remote = remote;

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) =>
      _remote.watchNotifications(userId);

  @override
  Future<void> markAsRead(String notificationId) =>
      _remote.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead(String userId) =>
      _remote.markAllAsRead(userId);
}
