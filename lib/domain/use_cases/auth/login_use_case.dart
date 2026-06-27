import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<void> execute({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
