import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/models/payment_model.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/services/notification_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  NotificationService? _notificationService;
  static const double EXPECTED_MONTHLY_PAYMENT = 100.0; // Make it configurable

  // Cache for monthly stats
  Map<String, dynamic>? _cachedStats;
  DateTime? _lastStatsUpdate;
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<void> initialize() async {
    _notificationService = await NotificationService.init();
    await _notificationService?.initialize();
  }

  Future<void> recordPayment(PaymentModel payment) async {
    final batch = _firestore.batch();

    // Add payment record
    final paymentRef = _firestore.collection('payments').doc();
    batch.set(paymentRef, payment.toMap());

    // Update user's last payment and total contributions
    final userRef = _firestore.collection('users').doc(payment.userId);
    batch.update(userRef, {
      'lastPayment': payment.date,
      'totalContributions': FieldValue.increment(payment.amount),
    });

    await batch.commit();

    // Get user data for notification
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      final user = UserModel.fromFirestore(userDoc);
      // Send payment confirmation notification
      await _notificationService?.sendPaymentConfirmation(user, payment.amount);

      // Add notification to Firestore
      await _firestore.collection('notifications').add({
        'userId': payment.userId,
        'type': 'payment',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'amount': payment.amount,
      });
    }
  }

  // Get payments for a specific user
  Stream<List<PaymentModel>> getUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  // Get all payments (for admin)
  Stream<List<PaymentModel>> getAllPayments() {
    return _firestore
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  // Get monthly summary as a stream
  Stream<Map<String, dynamic>> getMonthlyStatsStream() {
    return _firestore
        .collection('payments')
        .snapshots()
        .asyncMap((paymentsSnapshot) async {
      // Check if we can use cached data
      if (_cachedStats != null &&
          _lastStatsUpdate != null &&
          DateTime.now().difference(_lastStatsUpdate!) < _cacheDuration) {
        return _cachedStats!;
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get all non-admin users (this could also be cached/optimized if needed)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();
      final totalUsers = usersSnapshot.docs.length;

      // Filter payments for current month
      final monthlyPayments = paymentsSnapshot.docs
          .where((doc) =>
              (doc.data()['date'] as Timestamp).toDate().isAfter(startOfMonth))
          .toList();

      final monthlyTotal = monthlyPayments.fold<double>(
          0, (sum, doc) => sum + (doc.data()['amount'] as num).toDouble());
      final paidUsers =
          monthlyPayments.map((doc) => doc.data()['userId']).toSet().length;

      // Calculate collection rate and outstanding amount
      final collectionRate =
          totalUsers > 0 ? (paidUsers / totalUsers) * 100 : 0.0;
      final expectedTotal = totalUsers * EXPECTED_MONTHLY_PAYMENT;
      final outstanding = expectedTotal - monthlyTotal;

      // Cache the results
      _cachedStats = {
        'monthlyTotal': monthlyTotal,
        'paidCount': paidUsers,
        'totalUsers': totalUsers,
        'collectionRate': collectionRate,
        'outstanding': outstanding,
      };
      _lastStatsUpdate = DateTime.now();

      return _cachedStats!;
    });
  }

  // Check for users with overdue payments
  Future<void> checkAndNotifyOverduePayments() async {
    if (_notificationService == null) {
      await initialize();
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final usersSnapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: false)
        .get();

    for (var doc in usersSnapshot.docs) {
      final user = UserModel.fromFirestore(doc);
      if (user.lastPayment == null ||
          user.lastPayment!.isBefore(startOfMonth)) {
        // Send overdue notification
        await _notificationService?.sendOverdueNotification(user);
      }
    }
  }

  Stream<DocumentSnapshot> getUserPaymentStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getUserPaymentsStream(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }
}
