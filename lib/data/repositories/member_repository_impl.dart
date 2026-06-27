import 'package:our_community_fund/data/datasources/user_remote_data_source.dart';
import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  final UserRemoteDataSource _userRemote;

  MemberRepositoryImpl({required UserRemoteDataSource userRemote})
      : _userRemote = userRemote;

  @override
  Stream<List<User>> watchNonAdminMembers({int? limit}) {
    return _userRemote
        .watchNonAdminMembers(limit: limit)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
