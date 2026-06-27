/// Pure domain entity — no Firebase or framework dependencies.
class User {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final DateTime? lastPayment;
  final double totalContributions;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    this.lastPayment,
    required this.totalContributions,
    required this.createdAt,
  });

  User copyWith({
    String? name,
    String? email,
    bool? isAdmin,
    DateTime? lastPayment,
    double? totalContributions,
  }) {
    return User(
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
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
