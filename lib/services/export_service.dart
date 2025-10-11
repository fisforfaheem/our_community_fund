import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:our_community_fund/models/payment_model.dart';
import 'package:our_community_fund/models/user_model.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> exportPaymentsToCSV(
      {DateTime? startDate, DateTime? endDate}) async {
    // Header row
    String csvData = 'Date,User Name,Amount,Note,Recorded By\n';

    // Get payments
    Query query = _firestore.collection('payments').orderBy('date');
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final querySnapshot = await query.get();
    final payments = querySnapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList();

    // Add payment rows
    for (var payment in payments) {
      final date = DateFormat('yyyy-MM-dd').format(payment.date);
      final amount = payment.amount.toStringAsFixed(2);
      final note = payment.note?.replaceAll(',', ';') ?? '';

      csvData +=
          '$date,${payment.userName},$amount,$note,${payment.recordedBy}\n';
    }

    return csvData;
  }

  Future<String> exportUsersToCSV() async {
    // Header row
    String csvData = 'Name,Email,Total Contributions,Last Payment,Join Date\n';

    // Get users
    final querySnapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: false)
        .get();

    final users =
        querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

    // Add user rows
    for (var user in users) {
      final lastPayment = user.lastPayment != null
          ? DateFormat('yyyy-MM-dd').format(user.lastPayment!)
          : 'Never';
      final joinDate = DateFormat('yyyy-MM-dd').format(user.createdAt);

      csvData +=
          '${user.name},${user.email},${user.totalContributions.toStringAsFixed(2)},$lastPayment,$joinDate\n';
    }

    return csvData;
  }

  Future<String> exportMonthlyReportToCSV(int year, int month) async {
    // Header row
    String csvData = 'Metric,Value\n';

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    // Get payments for the month
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    final payments = paymentsSnapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList();

    // Calculate metrics
    final totalAmount =
        payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final uniqueUsers = payments.map((p) => p.userId).toSet().length;
    final averagePayment =
        payments.isEmpty ? 0.0 : totalAmount / payments.length;

    // Add metrics
    csvData += 'Total Amount,${totalAmount.toStringAsFixed(2)}\n';
    csvData += 'Number of Payments,${payments.length}\n';
    csvData += 'Unique Contributors,$uniqueUsers\n';
    csvData += 'Average Payment,${averagePayment.toStringAsFixed(2)}\n';

    return csvData;
  }
}
