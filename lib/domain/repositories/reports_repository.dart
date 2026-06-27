abstract class ReportsRepository {
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<String, dynamic>> getUserComplianceStats();
  Future<List<Map<String, dynamic>>> getUserPaymentSummary();

  Future<String> exportPaymentsToCsv({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<String> exportUserSummaryToCsv();
}
