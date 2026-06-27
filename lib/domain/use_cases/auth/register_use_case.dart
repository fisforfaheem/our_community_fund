import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<void> execute({
    required String email,
    required String password,
    required String name,
    bool isAdmin = false,
  }) {
    return _repository.register(
      email: email,
      password: password,
      name: name,
      isAdmin: isAdmin,
    );
  }
}
