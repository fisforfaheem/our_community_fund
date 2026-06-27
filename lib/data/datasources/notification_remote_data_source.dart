import 'package:cloud_firestore/cloud_firestore.dart';

abstract class NotificationRemoteDataSource {
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotificationRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList());
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
