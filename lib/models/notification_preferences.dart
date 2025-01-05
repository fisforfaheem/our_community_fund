import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferences {
  final bool paymentReminders;
  final bool paymentConfirmations;
  final bool systemUpdates;
  final bool emailNotifications;
  final String userId;

  NotificationPreferences({
    required this.paymentReminders,
    required this.paymentConfirmations,
    required this.systemUpdates,
    required this.emailNotifications,
    required this.userId,
  });

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationPreferences(
      paymentReminders: data['paymentReminders'] ?? true,
      paymentConfirmations: data['paymentConfirmations'] ?? true,
      systemUpdates: data['systemUpdates'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentReminders': paymentReminders,
      'paymentConfirmations': paymentConfirmations,
      'systemUpdates': systemUpdates,
      'emailNotifications': emailNotifications,
      'userId': userId,
    };
  }

  NotificationPreferences copyWith({
    bool? paymentReminders,
    bool? paymentConfirmations,
    bool? systemUpdates,
    bool? emailNotifications,
  }) {
    return NotificationPreferences(
      paymentReminders: paymentReminders ?? this.paymentReminders,
      paymentConfirmations: paymentConfirmations ?? this.paymentConfirmations,
      systemUpdates: systemUpdates ?? this.systemUpdates,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      userId: userId,
    );
  }
}
