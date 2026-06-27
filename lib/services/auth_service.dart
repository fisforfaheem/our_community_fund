import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:our_community_fund/data/datasources/auth_remote_data_source.dart';
import 'package:our_community_fund/data/datasources/user_remote_data_source.dart';
import 'package:our_community_fund/data/models/user_model.dart';
import 'package:our_community_fund/data/repositories/auth_repository_impl.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';

/// Thin facade over [AuthRepository] for screens not yet migrated to use cases.
/// New code should prefer use cases from `context.read<LoginUseCase>()`, etc.
class AuthService {
  final AuthRepository _repository;
  final firebase_auth.FirebaseAuth _auth;

  AuthService({
    AuthRepository? repository,
    firebase_auth.FirebaseAuth? auth,
  })  : _repository = repository ??
            AuthRepositoryImpl(
              authRemote: AuthRemoteDataSourceImpl(),
              userRemote: UserRemoteDataSourceImpl(),
            ),
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Firebase auth stream — kept for legacy screens that expect [User].
  Stream<firebase_auth.User?> get authStateChanges =>
      _auth.authStateChanges();

  Future<void> signInWithEmailAndPassword(String email, String password) {
    return _repository.signIn(email: email, password: password);
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    bool isAdmin,
  ) {
    return _repository.register(
      email: email,
      password: password,
      name: name,
      isAdmin: isAdmin,
    );
  }

  Future<void> signOut() => _repository.signOut();

  Future<void> resetPassword(String email) =>
      _repository.resetPassword(email: email);

  Future<UserModel> getCurrentUser() async {
    final user = await _repository.getCurrentUser();
    return UserModel.fromEntity(user);
  }

  Future<void> updateUserProfile(String userId, String name) =>
      _repository.updateUserProfile(userId: userId, name: name);
}
