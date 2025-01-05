import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final String recordedBy;
  final String type;
  final String? note;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    required this.recordedBy,
    this.type = 'regular',
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'date': date,
      'recordedBy': recordedBy,
      'type': type,
      if (note != null) 'note': note,
    };
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      recordedBy: data['recordedBy'],
      type: data['type'] ?? 'regular',
      note: data['note'],
    );
  }
}
