import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Record user action
  Future<void> recordUserAction({
    required String action,
    required String category,
    Map<String, dynamic>? details,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('user_history').add({
      'userId': userId,
      'action': action,
      'category': category,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Record payment history
  Future<void> recordPaymentHistory({
    required String userId,
    required double amount,
    required String type,
    String? note,
  }) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) return;

    await _firestore.collection('payment_history').add({
      'userId': userId,
      'adminId': adminId,
      'amount': amount,
      'type': type,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Record support request history
  Future<void> recordSupportHistory({
    required String userId,
    required String requestId,
    required String action,
    required String status,
    String? note,
  }) async {
    final adminId = _auth.currentUser?.uid;

    await _firestore.collection('support_history').add({
      'userId': userId,
      'requestId': requestId,
      'adminId': adminId,
      'action': action,
      'status': status,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Record system event
  Future<void> recordSystemEvent({
    required String event,
    required String category,
    Map<String, dynamic>? details,
  }) async {
    await _firestore.collection('system_history').add({
      'event': event,
      'category': category,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get user history
  Stream<QuerySnapshot> getUserHistory(String userId) {
    return _firestore
        .collection('user_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get payment history
  Stream<QuerySnapshot> getPaymentHistory(String userId) {
    return _firestore
        .collection('payment_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get support history
  Stream<QuerySnapshot> getSupportHistory(String userId) {
    return _firestore
        .collection('support_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get system history
  Stream<QuerySnapshot> getSystemHistory({String? category}) {
    Query query = _firestore.collection('system_history');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Get admin activity history
  Stream<QuerySnapshot> getAdminHistory(String adminId) {
    return _firestore
        .collection('payment_history')
        .where('adminId', isEqualTo: adminId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete history older than specified duration
  Future<void> cleanupOldHistory(Duration age) async {
    final cutoffDate = DateTime.now().subtract(age);

    final batch = _firestore.batch();
    final collections = [
      'user_history',
      'payment_history',
      'support_history',
      'system_history'
    ];

    for (final collectionName in collections) {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  // Export history for a specific user
  Future<Map<String, List<Map<String, dynamic>>>> exportUserHistory(
    String userId,
  ) async {
    final userHistory = await _firestore
        .collection('user_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp')
        .get();

    final paymentHistory = await _firestore
        .collection('payment_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp')
        .get();

    final supportHistory = await _firestore
        .collection('support_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp')
        .get();

    return {
      'user_actions':
          userHistory.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      'payments': paymentHistory.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
      'support_requests': supportHistory.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    };
  }
}
