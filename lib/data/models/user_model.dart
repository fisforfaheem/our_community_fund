import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/domain/entities/user.dart';

/// Firestore DTO for user documents. Maps to/from the domain [User] entity.
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
    final data = doc.data() as Map<String, dynamic>;
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

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      isAdmin: user.isAdmin,
      lastPayment: user.lastPayment,
      totalContributions: user.totalContributions,
      createdAt: user.createdAt,
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

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      isAdmin: isAdmin,
      lastPayment: lastPayment,
      totalContributions: totalContributions,
      createdAt: createdAt,
    );
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
