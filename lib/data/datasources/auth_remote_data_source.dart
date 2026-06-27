import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote data source for Firebase Authentication operations.
abstract class AuthRemoteDataSource {
  Stream<String?> get authStateChanges;
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool isAdmin,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(result.user!.uid).set({
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
      'lastPayment': null,
      'totalContributions': 0,
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
