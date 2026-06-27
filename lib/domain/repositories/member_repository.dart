import 'package:our_community_fund/domain/entities/user.dart';

abstract class MemberRepository {
  Stream<List<User>> watchNonAdminMembers({int? limit});
}
