import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/data/datasources/payment_remote_data_source.dart';
import 'package:our_community_fund/data/models/payment_model.dart';
import 'package:our_community_fund/data/models/user_model.dart';
import 'package:our_community_fund/domain/entities/payment.dart';
import 'package:our_community_fund/domain/entities/payment_request.dart';
import 'package:our_community_fund/domain/repositories/payment_repository.dart';
import 'package:our_community_fund/services/notification_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remote;
  NotificationService? _notificationService;

  Map<String, dynamic>? _cachedStats;
  DateTime? _lastStatsUpdate;
  static const _cacheDuration = Duration(minutes: 5);

  PaymentRepositoryImpl({
    required PaymentRemoteDataSource remote,
    NotificationService? notificationService,
  })  : _remote = remote,
        _notificationService = notificationService;

  Future<NotificationService> _notifications() async {
    _notificationService ??= await NotificationService.init();
    await _notificationService!.initialize();
    return _notificationService!;
  }

  @override
  Future<void> recordPayment(Payment payment) async {
    final model = PaymentModel.fromEntity(payment);
    await _remote.createPayment(model);
    await _remote.updateUserAfterPayment(
      userId: payment.userId,
      date: payment.date,
      amount: payment.amount,
    );

    final userData = await _remote.getUserData(payment.userId);
    final user = UserModel(
      id: payment.userId,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      isAdmin: userData['isAdmin'] ?? false,
      lastPayment: payment.date,
      totalContributions: (userData['totalContributions'] ?? 0).toDouble(),
      createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
    );

    final notifications = await _notifications();
    await notifications.sendPaymentConfirmation(user, payment.amount);
    await _remote.addNotification({
      'userId': payment.userId,
      'type': 'payment',
      'title': 'Payment Received',
      'body':
          'Thank you for your payment of \$${payment.amount.toStringAsFixed(2)}',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  @override
  Future<void> recordExtraContribution({
    required String userId,
    required double amount,
    required String note,
  }) async {
    final userData = await _remote.getUserData(userId);
    final payment = PaymentModel(
      id: '',
      userId: userId,
      userName: userData['name'] as String,
      amount: amount,
      date: DateTime.now(),
      recordedBy: userId,
      type: 'extra',
      note: note,
    );
    await _remote.createPayment(payment);
    await _remote.updateUserExtraContribution(userId: userId, amount: amount);

    final user = UserModel(
      id: userId,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      isAdmin: false,
      totalContributions: (userData['totalContributions'] ?? 0).toDouble(),
      createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
    );
    final notifications = await _notifications();
    await notifications.sendExtraContributionConfirmation(user, amount);
    await _remote.addNotification({
      'userId': userId,
      'type': 'extra_contribution',
      'title': 'Extra Contribution Received',
      'body':
          'Thank you for your extra contribution of \$${amount.toStringAsFixed(2)}',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  @override
  Future<double> getUserExtraContributions(String userId) =>
      _remote.getUserExtraContributions(userId);

  @override
  Stream<List<Payment>> watchUserPayments(String userId, {int limit = 10}) {
    return _remote
        .watchUserPayments(userId, limit: limit)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<Payment>> watchAllPayments() {
    return _remote
        .watchAllPayments()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<Payment>> watchRecentPayments({int limit = 5}) {
    return _remote
        .watchRecentPayments(limit: limit)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<Map<String, dynamic>> watchMonthlyStats() {
    return _remote.watchPaymentsSnapshot().asyncMap((_) async {
      if (_cachedStats != null &&
          _lastStatsUpdate != null &&
          DateTime.now().difference(_lastStatsUpdate!) < _cacheDuration) {
        return _cachedStats!;
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final users = await _remote.getNonAdminUsers();
      final totalUsers = users.length;

      final paymentsSnapshot = await _remote.watchPaymentsSnapshot().first;
      final monthlyPayments = paymentsSnapshot.docs.where((doc) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        return date.isAfter(startOfMonth);
      }).toList();

      final monthlyTotal = monthlyPayments.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
      );
      final paidUsers =
          monthlyPayments.map((doc) => doc.data()['userId']).toSet().length;
      final collectionRate =
          totalUsers > 0 ? (paidUsers / totalUsers) * 100 : 0.0;
      final expectedTotal = totalUsers * PaymentRepository.expectedMonthlyPayment;
      final outstanding = expectedTotal - monthlyTotal;

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

  @override
  Stream<List<PaymentRequest>> watchPaymentRequests({String? status}) {
    return _remote
        .watchPaymentRequests(status: status)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<int> watchPendingPaymentRequestCount() {
    return watchPaymentRequests(status: 'pending')
        .map((requests) => requests.length);
  }

  @override
  Stream<List<PaymentRequest>> watchUserPaymentRequests(String userId) {
    return _remote
        .watchUserPaymentRequests(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> submitPaymentRequest({
    required String userId,
    required String userName,
    required double amount,
    String? note,
  }) {
    return _remote.submitPaymentRequest(
      userId: userId,
      userName: userName,
      amount: amount,
      note: note,
    );
  }

  @override
  Future<void> verifyPaymentRequest(PaymentRequest request) async {
    await _remote.updatePaymentRequestStatus(request.id, 'verified');
    await recordPayment(Payment(
      id: '',
      userId: request.userId,
      userName: request.userName,
      amount: request.amount,
      date: request.timestamp,
      recordedBy: 'Admin (Verified)',
      note: request.note,
    ));
  }

  @override
  Future<void> rejectPaymentRequest(PaymentRequest request) async {
    await _remote.updatePaymentRequestStatus(request.id, 'rejected');
    final notifications = await _notifications();
    await notifications.sendNotificationToUser(
      userId: request.userId,
      title: 'Payment Request Rejected',
      body:
          'Your payment request of \$${request.amount} has been rejected. Please contact admin for more information.',
    );
  }

  @override
  Future<Map<String, dynamic>> getPaymentSettings() async {
    final existing = await _remote.getPaymentSettingsDoc();
    if (existing != null) return existing;

    final defaults = {
      'standardAmount': 50.0,
      'reminderDay': 25,
      'gracePeriodDays': 5,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    await _remote.setPaymentSettings(defaults);
    return {
      'standardAmount': 50.0,
      'reminderDay': 25,
      'gracePeriodDays': 5,
    };
  }

  @override
  Future<void> savePaymentSettings(Map<String, dynamic> settings) {
    return _remote.setPaymentSettings({
      ...settings,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> checkAndNotifyOverduePayments() async {
    final notifications = await _notifications();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final users = await _remote.getNonAdminUsers();

    for (final userDoc in users) {
      final lastPaymentRaw = userDoc.data['lastPayment'];
      final lastPayment = lastPaymentRaw is Timestamp
          ? lastPaymentRaw.toDate()
          : null;
      if (lastPayment == null || lastPayment.isBefore(startOfMonth)) {
        final user = UserModel(
          id: userDoc.id,
          name: userDoc.data['name'] ?? '',
          email: userDoc.data['email'] ?? '',
          isAdmin: false,
          lastPayment: lastPayment,
          totalContributions:
              (userDoc.data['totalContributions'] ?? 0).toDouble(),
          createdAt: userDoc.data['createdAt']?.toDate() ?? DateTime.now(),
        );
        await notifications.sendOverdueNotification(user);
      }
    }
  }

  @override
  Future<int> deleteAllDocumentsInCollections(List<String> collectionNames) {
    return _remote.deleteAllInCollections(collectionNames);
  }
}
