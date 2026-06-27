import 'package:our_community_fund/data/datasources/reports_remote_data_source.dart';
import 'package:our_community_fund/data/repositories/reports_repository_impl.dart';
import 'package:our_community_fund/domain/repositories/reports_repository.dart';

/// Thin facade over [ReportsRepository] for legacy call sites.
class ReportsService {
  final ReportsRepository _repository;

  ReportsService({ReportsRepository? repository})
      : _repository = repository ??
            ReportsRepositoryImpl(
              remote: ReportsRemoteDataSourceImpl(),
            );

  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _repository.getPaymentStats(startDate: startDate, endDate: endDate);

  Future<Map<String, dynamic>> getUserComplianceStats() =>
      _repository.getUserComplianceStats();

  Future<List<Map<String, dynamic>>> getUserPaymentSummary() =>
      _repository.getUserPaymentSummary();

  Future<String> exportPaymentsToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _repository.exportPaymentsToCsv(startDate: startDate, endDate: endDate);

  Future<String> exportUserSummaryToCSV() =>
      _repository.exportUserSummaryToCsv();
}
