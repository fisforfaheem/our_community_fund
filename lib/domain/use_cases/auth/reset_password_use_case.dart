import 'package:our_community_fund/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<void> execute({required String email}) {
    return _repository.resetPassword(email: email);
  }
}
