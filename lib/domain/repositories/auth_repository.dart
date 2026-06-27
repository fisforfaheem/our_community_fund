import 'package:our_community_fund/domain/entities/user.dart';

/// Contract for authentication and user-profile operations.
/// Presentation and use-case layers depend on this interface only.
abstract class AuthRepository {
  /// Stream of authenticated user IDs; null when signed out.
  Stream<String?> get authStateChanges;

  /// Currently signed-in user ID, or null.
  String? get currentUserId;

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool isAdmin,
  });

  Future<void> signOut();

  Future<void> resetPassword({required String email});

  Future<User> getCurrentUser();

  Future<void> updateUserProfile({required String userId, required String name});

  /// Real-time stream of user profile data from Firestore.
  Stream<User?> watchUserData(String uid);
}
