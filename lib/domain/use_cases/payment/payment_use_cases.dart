import 'package:our_community_fund/domain/entities/payment.dart';
import 'package:our_community_fund/domain/entities/payment_request.dart';
import 'package:our_community_fund/domain/repositories/payment_repository.dart';

class RecordPaymentUseCase {
  final PaymentRepository _repository;
  RecordPaymentUseCase(this._repository);
  Future<void> execute(Payment payment) => _repository.recordPayment(payment);
}

class RecordExtraContributionUseCase {
  final PaymentRepository _repository;
  RecordExtraContributionUseCase(this._repository);
  Future<void> execute({
    required String userId,
    required double amount,
    required String note,
  }) =>
      _repository.recordExtraContribution(
        userId: userId,
        amount: amount,
        note: note,
      );
}

class WatchUserPaymentsUseCase {
  final PaymentRepository _repository;
  WatchUserPaymentsUseCase(this._repository);
  Stream<List<Payment>> execute(String userId, {int limit = 10}) =>
      _repository.watchUserPayments(userId, limit: limit);
}

class WatchRecentPaymentsUseCase {
  final PaymentRepository _repository;
  WatchRecentPaymentsUseCase(this._repository);
  Stream<List<Payment>> execute({int limit = 5}) =>
      _repository.watchRecentPayments(limit: limit);
}

class WatchMonthlyStatsUseCase {
  final PaymentRepository _repository;
  WatchMonthlyStatsUseCase(this._repository);
  Stream<Map<String, dynamic>> execute() => _repository.watchMonthlyStats();
}

class WatchPaymentRequestsUseCase {
  final PaymentRepository _repository;
  WatchPaymentRequestsUseCase(this._repository);
  Stream<List<PaymentRequest>> execute({String? status}) =>
      _repository.watchPaymentRequests(status: status);
}

class WatchUserPaymentRequestsUseCase {
  final PaymentRepository _repository;
  WatchUserPaymentRequestsUseCase(this._repository);
  Stream<List<PaymentRequest>> execute(String userId) =>
      _repository.watchUserPaymentRequests(userId);
}

class WatchPendingPaymentRequestCountUseCase {
  final PaymentRepository _repository;
  WatchPendingPaymentRequestCountUseCase(this._repository);
  Stream<int> execute() => _repository.watchPendingPaymentRequestCount();
}

class SubmitPaymentRequestUseCase {
  final PaymentRepository _repository;
  SubmitPaymentRequestUseCase(this._repository);
  Future<void> execute({
    required String userId,
    required String userName,
    required double amount,
    String? note,
  }) =>
      _repository.submitPaymentRequest(
        userId: userId,
        userName: userName,
        amount: amount,
        note: note,
      );
}

class VerifyPaymentRequestUseCase {
  final PaymentRepository _repository;
  VerifyPaymentRequestUseCase(this._repository);
  Future<void> execute(PaymentRequest request) =>
      _repository.verifyPaymentRequest(request);
}

class RejectPaymentRequestUseCase {
  final PaymentRepository _repository;
  RejectPaymentRequestUseCase(this._repository);
  Future<void> execute(PaymentRequest request) =>
      _repository.rejectPaymentRequest(request);
}

class GetPaymentSettingsUseCase {
  final PaymentRepository _repository;
  GetPaymentSettingsUseCase(this._repository);
  Future<Map<String, dynamic>> execute() => _repository.getPaymentSettings();
}

class SavePaymentSettingsUseCase {
  final PaymentRepository _repository;
  SavePaymentSettingsUseCase(this._repository);
  Future<void> execute(Map<String, dynamic> settings) =>
      _repository.savePaymentSettings(settings);
}

class DeleteAllCollectionsUseCase {
  final PaymentRepository _repository;
  DeleteAllCollectionsUseCase(this._repository);
  Future<int> execute(List<String> collectionNames) =>
      _repository.deleteAllDocumentsInCollections(collectionNames);
}
