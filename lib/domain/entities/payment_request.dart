/// A user-submitted payment awaiting admin verification.
class PaymentRequest {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String? note;
  final String status;
  final DateTime timestamp;

  const PaymentRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    this.note,
    required this.status,
    required this.timestamp,
  });
}
