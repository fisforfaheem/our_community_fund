import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final DateTime? lastPayment;
  final double totalContributions;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    this.lastPayment,
    required this.totalContributions,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      lastPayment: data['lastPayment']?.toDate(),
      totalContributions: (data['totalContributions'] ?? 0).toDouble(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'lastPayment': lastPayment,
      'totalContributions': totalContributions,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    bool? isAdmin,
    DateTime? lastPayment,
    double? totalContributions,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      lastPayment: lastPayment ?? this.lastPayment,
      totalContributions: totalContributions ?? this.totalContributions,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
