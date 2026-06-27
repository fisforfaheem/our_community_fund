import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/domain/entities/payment_request.dart';

class PaymentRequestModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String? note;
  final String status;
  final DateTime timestamp;

  PaymentRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    this.note,
    required this.status,
    required this.timestamp,
  });

  factory PaymentRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRequestModel(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      amount: (data['amount'] as num).toDouble(),
      note: data['note'],
      status: data['status'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  PaymentRequest toEntity() {
    return PaymentRequest(
      id: id,
      userId: userId,
      userName: userName,
      amount: amount,
      note: note,
      status: status,
      timestamp: timestamp,
    );
  }
}
