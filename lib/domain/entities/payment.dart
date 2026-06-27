/// Pure domain entity for a payment record.
class Payment {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final String recordedBy;
  final String type;
  final String? note;

  const Payment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    required this.recordedBy,
    this.type = 'regular',
    this.note,
  });
}
