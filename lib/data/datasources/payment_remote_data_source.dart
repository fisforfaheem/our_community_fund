import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/data/models/payment_model.dart';
import 'package:our_community_fund/data/models/payment_request_model.dart';

abstract class PaymentRemoteDataSource {
  Future<void> createPayment(PaymentModel payment);
  Future<void> updateUserAfterPayment({
    required String userId,
    required DateTime date,
    required double amount,
  });
  Future<void> updateUserExtraContribution({
    required String userId,
    required double amount,
  });
  Future<Map<String, dynamic>> getUserData(String userId);
  Future<double> getUserExtraContributions(String userId);

  Stream<List<PaymentModel>> watchUserPayments(String userId, {int limit = 10});
  Stream<List<PaymentModel>> watchAllPayments();
  Stream<List<PaymentModel>> watchRecentPayments({int limit = 5});
  Stream<List<PaymentRequestModel>> watchPaymentRequests({String? status});
  Stream<List<PaymentRequestModel>> watchUserPaymentRequests(String userId);

  Future<void> submitPaymentRequest({
    required String userId,
    required String userName,
    required double amount,
    String? note,
  });
  Future<void> updatePaymentRequestStatus(String id, String status);
  Future<void> addNotification(Map<String, dynamic> data);

  Future<Map<String, dynamic>?> getPaymentSettingsDoc();
  Future<void> setPaymentSettings(Map<String, dynamic> settings);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPaymentsSnapshot();
  Future<List<UserModelDoc>> getNonAdminUsers();
  Future<int> deleteAllInCollections(List<String> names);
}

/// ponytail: lightweight tuple for user fetch during payment flows.
class UserModelDoc {
  final String id;
  final Map<String, dynamic> data;
  UserModelDoc(this.id, this.data);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createPayment(PaymentModel payment) async {
    await _firestore.collection('payments').add(payment.toMap());
  }

  @override
  Future<void> updateUserAfterPayment({
    required String userId,
    required DateTime date,
    required double amount,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'lastPayment': date,
      'totalContributions': FieldValue.increment(amount),
    });
  }

  @override
  Future<void> updateUserExtraContribution({
    required String userId,
    required double amount,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'totalContributions': FieldValue.increment(amount),
      'lastExtraContribution': DateTime.now(),
    });
  }

  @override
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found');
    return doc.data()!;
  }

  @override
  Future<double> getUserExtraContributions(String userId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'extra')
        .get();
    return snapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
    );
  }

  @override
  Stream<List<PaymentModel>> watchUserPayments(String userId, {int limit = 10}) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromFirestore).toList());
  }

  @override
  Stream<List<PaymentModel>> watchAllPayments() {
    return _firestore
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromFirestore).toList());
  }

  @override
  Stream<List<PaymentModel>> watchRecentPayments({int limit = 5}) {
    return _firestore
        .collection('payments')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PaymentModel.fromFirestore).toList());
  }

  @override
  Stream<List<PaymentRequestModel>> watchPaymentRequests({String? status}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('payment_requests').orderBy('timestamp', descending: true);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query
        .snapshots()
        .map((s) => s.docs.map(PaymentRequestModel.fromFirestore).toList());
  }

  @override
  Future<void> submitPaymentRequest({
    required String userId,
    required String userName,
    required double amount,
    String? note,
  }) async {
    await _firestore.collection('payment_requests').add({
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'note': note,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<PaymentRequestModel>> watchUserPaymentRequests(String userId) {
    return _firestore
        .collection('payment_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PaymentRequestModel.fromFirestore).toList());
  }

  @override
  Future<void> updatePaymentRequestStatus(String id, String status) async {
    await _firestore.collection('payment_requests').doc(id).update({'status': status});
  }

  @override
  Future<void> addNotification(Map<String, dynamic> data) async {
    await _firestore.collection('notifications').add(data);
  }

  @override
  Future<Map<String, dynamic>?> getPaymentSettingsDoc() async {
    final doc = await _firestore.collection('settings').doc('payments').get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> setPaymentSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('payments').set(settings);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPaymentsSnapshot() {
    return _firestore.collection('payments').snapshots();
  }

  @override
  Future<List<UserModelDoc>> getNonAdminUsers() async {
    final snapshot =
        await _firestore.collection('users').where('isAdmin', isEqualTo: false).get();
    return snapshot.docs.map((d) => UserModelDoc(d.id, d.data())).toList();
  }

  @override
  Future<int> deleteAllInCollections(List<String> names) async {
    int totalDeleted = 0;
    for (final name in names) {
      final snapshot = await _firestore.collection(name).get();
      var batch = _firestore.batch();
      var count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        totalDeleted++;
        if (count >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    }
    return totalDeleted;
  }
}
