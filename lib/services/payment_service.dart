import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/data/datasources/payment_remote_data_source.dart';
import 'package:our_community_fund/data/models/payment_model.dart';
import 'package:our_community_fund/data/repositories/payment_repository_impl.dart';
import 'package:our_community_fund/domain/repositories/payment_repository.dart';

/// Thin facade over [PaymentRepository] for legacy call sites.
class PaymentService {
  final PaymentRepository _repository;

  PaymentService({PaymentRepository? repository})
      : _repository = repository ??
            PaymentRepositoryImpl(
              remote: PaymentRemoteDataSourceImpl(),
            );

  static const double EXPECTED_MONTHLY_PAYMENT =
      PaymentRepository.expectedMonthlyPayment;

  Future<void> recordPayment(PaymentModel payment) =>
      _repository.recordPayment(payment.toEntity());

  Future<void> recordExtraContribution(
    String userId,
    double amount,
    String note,
  ) =>
      _repository.recordExtraContribution(
        userId: userId,
        amount: amount,
        note: note,
      );

  Future<double> getUserExtraContributions(String userId) =>
      _repository.getUserExtraContributions(userId);

  Stream<List<PaymentModel>> getUserPayments(String userId) {
    return _repository.watchUserPayments(userId).map(
          (payments) =>
              payments.map(PaymentModel.fromEntity).toList(),
        );
  }

  Stream<List<PaymentModel>> getAllPayments() {
    return _repository.watchAllPayments().map(
          (payments) =>
              payments.map(PaymentModel.fromEntity).toList(),
        );
  }

  Stream<Map<String, dynamic>> getMonthlyStatsStream() =>
      _repository.watchMonthlyStats();

  Future<void> checkAndNotifyOverduePayments() =>
      _repository.checkAndNotifyOverduePayments();

  Stream<DocumentSnapshot> getUserPaymentStatus(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPaymentsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }
}
