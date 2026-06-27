import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class UpdateUserProfileUseCase {
  final AuthRepository _repository;

  UpdateUserProfileUseCase(this._repository);

  Future<void> execute({required String userId, required String name}) {
    return _repository.updateUserProfile(userId: userId, name: name);
  }
}
