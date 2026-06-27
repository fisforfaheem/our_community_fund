import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<User> execute() => _repository.getCurrentUser();
}
