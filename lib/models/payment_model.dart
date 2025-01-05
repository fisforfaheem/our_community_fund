import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final String? note;
  final String recordedBy;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    this.note,
    required this.recordedBy,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
      recordedBy: data['recordedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'recordedBy': recordedBy,
    };
  }
}
