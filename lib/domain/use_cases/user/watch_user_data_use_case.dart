import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class WatchUserDataUseCase {
  final AuthRepository _repository;

  WatchUserDataUseCase(this._repository);

  Stream<User?> execute(String uid) => _repository.watchUserData(uid);
}
