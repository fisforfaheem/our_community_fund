import 'package:our_community_fund/domain/repositories/reports_repository.dart';

class GetPaymentStatsUseCase {
  final ReportsRepository _repository;
  GetPaymentStatsUseCase(this._repository);
  Future<Map<String, dynamic>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _repository.getPaymentStats(startDate: startDate, endDate: endDate);
}

class GetUserComplianceStatsUseCase {
  final ReportsRepository _repository;
  GetUserComplianceStatsUseCase(this._repository);
  Future<Map<String, dynamic>> execute() =>
      _repository.getUserComplianceStats();
}

class GetUserPaymentSummaryUseCase {
  final ReportsRepository _repository;
  GetUserPaymentSummaryUseCase(this._repository);
  Future<List<Map<String, dynamic>>> execute() =>
      _repository.getUserPaymentSummary();
}

class ExportPaymentsCsvUseCase {
  final ReportsRepository _repository;
  ExportPaymentsCsvUseCase(this._repository);
  Future<String> execute({DateTime? startDate, DateTime? endDate}) =>
      _repository.exportPaymentsToCsv(startDate: startDate, endDate: endDate);
}

class ExportUserSummaryCsvUseCase {
  final ReportsRepository _repository;
  ExportUserSummaryCsvUseCase(this._repository);
  Future<String> execute() => _repository.exportUserSummaryToCsv();
}
