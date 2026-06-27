import 'package:our_community_fund/data/datasources/auth_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/user_remote_data_source.dart';
import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemote;
  final UserRemoteDataSource _userRemote;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authRemote,
    required UserRemoteDataSource userRemote,
  })  : _authRemote = authRemote,
        _userRemote = userRemote;

  @override
  Stream<String?> get authStateChanges => _authRemote.authStateChanges;

  @override
  String? get currentUserId => _authRemote.currentUserId;

  @override
  Future<void> signIn({required String email, required String password}) {
    return _authRemote.signIn(email: email, password: password);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool isAdmin,
  }) {
    return _authRemote.register(
      email: email,
      password: password,
      name: name,
      isAdmin: isAdmin,
    );
  }

  @override
  Future<void> signOut() => _authRemote.signOut();

  @override
  Future<void> resetPassword({required String email}) {
    return _authRemote.resetPassword(email: email);
  }

  @override
  Future<User> getCurrentUser() async {
    final uid = _authRemote.currentUserId;
    if (uid == null) {
      throw Exception('No user is currently signed in');
    }
    final model = await _userRemote.getUser(uid);
    return model.toEntity();
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String name,
  }) async {
    try {
      await _userRemote.updateProfile(userId: userId, name: name);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Stream<User?> watchUserData(String uid) {
    return _userRemote.watchUser(uid).map((model) => model?.toEntity());
  }
}
