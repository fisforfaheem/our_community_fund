import 'package:our_community_fund/data/datasources/reports_remote_data_source.dart';
import 'package:our_community_fund/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remote;

  ReportsRepositoryImpl({required ReportsRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _remote.getPaymentStats(startDate: startDate, endDate: endDate);

  @override
  Future<Map<String, dynamic>> getUserComplianceStats() =>
      _remote.getUserComplianceStats();

  @override
  Future<List<Map<String, dynamic>>> getUserPaymentSummary() =>
      _remote.getUserPaymentSummary();

  @override
  Future<String> exportPaymentsToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _remote.exportPaymentsToCsv(startDate: startDate, endDate: endDate);

  @override
  Future<String> exportUserSummaryToCsv() => _remote.exportUserSummaryToCsv();
}
