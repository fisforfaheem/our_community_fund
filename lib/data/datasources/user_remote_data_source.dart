import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/data/models/user_model.dart';

/// Remote data source for Firestore user profile operations.
abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String uid);
  Future<void> updateProfile({required String userId, required String name});
  Stream<UserModel?> watchUser(String uid);
  Stream<List<UserModel>> watchNonAdminMembers({int? limit});
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User data not found');
    }
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String name,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Stream<List<UserModel>> watchNonAdminMembers({int? limit}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('users').where('isAdmin', isEqualTo: false);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map(UserModel.fromFirestore).toList());
  }
}
