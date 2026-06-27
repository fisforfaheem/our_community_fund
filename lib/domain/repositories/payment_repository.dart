import 'package:our_community_fund/domain/entities/payment.dart';
import 'package:our_community_fund/domain/entities/payment_request.dart';

abstract class PaymentRepository {
  static const double expectedMonthlyPayment = 100.0;

  Future<void> recordPayment(Payment payment);
  Future<void> recordExtraContribution({
    required String userId,
    required double amount,
    required String note,
  });
  Future<double> getUserExtraContributions(String userId);

  Stream<List<Payment>> watchUserPayments(String userId, {int limit = 10});
  Stream<List<Payment>> watchAllPayments();
  Stream<List<Payment>> watchRecentPayments({int limit = 5});
  Stream<Map<String, dynamic>> watchMonthlyStats();

  Stream<List<PaymentRequest>> watchPaymentRequests({String? status});
  Stream<List<PaymentRequest>> watchUserPaymentRequests(String userId);
  Stream<int> watchPendingPaymentRequestCount();

  Future<void> submitPaymentRequest({
    required String userId,
    required String userName,
    required double amount,
    String? note,
  });
  Future<void> verifyPaymentRequest(PaymentRequest request);
  Future<void> rejectPaymentRequest(PaymentRequest request);

  Future<Map<String, dynamic>> getPaymentSettings();
  Future<void> savePaymentSettings(Map<String, dynamic> settings);

  Future<void> checkAndNotifyOverduePayments();
  Future<int> deleteAllDocumentsInCollections(List<String> collectionNames);
}
