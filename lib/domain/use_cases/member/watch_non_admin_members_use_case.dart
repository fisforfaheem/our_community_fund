import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/repositories/member_repository.dart';

class WatchNonAdminMembersUseCase {
  final MemberRepository _repository;
  WatchNonAdminMembersUseCase(this._repository);
  Stream<List<User>> execute({int? limit}) =>
      _repository.watchNonAdminMembers(limit: limit);
}
