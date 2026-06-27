import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:our_community_fund/core/utils/logger.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Map<String, dynamic>> getUserComplianceStats();
  Future<List<Map<String, dynamic>>> getUserPaymentSummary();
  Future<String> exportPaymentsToCsv({DateTime? startDate, DateTime? endDate});
  Future<String> exportUserSummaryToCsv();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReportsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('payments').orderBy('date');
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }
      final payments = (await query.get()).docs;
      final totalAmount = payments.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
      );
      final uniqueUsers =
          payments.map((doc) => doc.data()['userId'] as String).toSet().length;
      final averagePayment =
          payments.isEmpty ? 0.0 : totalAmount / payments.length;
      final monthlyTrends = <String, double>{};
      for (final doc in payments) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0) +
            (doc.data()['amount'] as num).toDouble();
      }
      return {
        'totalAmount': totalAmount,
        'paymentCount': payments.length,
        'uniqueUsers': uniqueUsers,
        'averagePayment': averagePayment,
        'monthlyTrends': monthlyTrends,
      };
    } catch (e) {
      AppLogger.error('Error getting payment stats', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserComplianceStats() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();
      var compliantUsers = 0;
      var partiallyCompliantUsers = 0;
      var nonCompliantUsers = 0;
      for (final userDoc in usersSnapshot.docs) {
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userDoc.id)
            .where('date', isGreaterThanOrEqualTo: startOfYear)
            .get();
        final monthsPaid = paymentsSnapshot.docs
            .map((doc) {
              final date = (doc.data()['date'] as Timestamp).toDate();
              return '${date.year}-${date.month}';
            })
            .toSet()
            .length;
        final complianceRate = monthsPaid / now.month;
        if (complianceRate >= 1) {
          compliantUsers++;
        } else if (complianceRate >= 0.7) {
          partiallyCompliantUsers++;
        } else {
          nonCompliantUsers++;
        }
      }
      return {
        'compliantUsers': compliantUsers,
        'partiallyCompliantUsers': partiallyCompliantUsers,
        'nonCompliantUsers': nonCompliantUsers,
        'totalUsers': usersSnapshot.docs.length,
      };
    } catch (e) {
      AppLogger.error('Error getting user compliance stats', e);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserPaymentSummary() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();
      final summary = <Map<String, dynamic>>[];
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userDoc.id)
            .where('date', isGreaterThanOrEqualTo: startOfYear)
            .get();
        final totalAmount = paymentsSnapshot.docs.fold<double>(
          0,
          (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
        );
        final monthsPaid = paymentsSnapshot.docs
            .map((doc) {
              final date = (doc.data()['date'] as Timestamp).toDate();
              return '${date.year}-${date.month}';
            })
            .toSet()
            .length;
        final lastPayment = paymentsSnapshot.docs.isNotEmpty
            ? (paymentsSnapshot.docs.first.data()['date'] as Timestamp).toDate()
            : null;
        summary.add({
          'userId': userDoc.id,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'totalAmount': totalAmount,
          'monthsPaid': monthsPaid,
          'lastPayment': lastPayment?.toIso8601String(),
          'isCurrentMonth': lastPayment?.month == DateTime.now().month,
        });
      }
      return summary;
    } catch (e) {
      AppLogger.error('Error getting user payment summary', e);
      rethrow;
    }
  }

  @override
  Future<String> exportPaymentsToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('payments').orderBy('date');
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }
      final payments = (await query.get()).docs;
      final csvData = <List<dynamic>>[
        ['Date', 'User', 'Amount', 'Type', 'Note', 'Recorded By'],
      ];
      for (final doc in payments) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        csvData.add([
          date.toIso8601String(),
          data['userName'] ?? 'Unknown',
          data['amount']?.toString() ?? '0',
          data['type'] ?? '',
          data['note'] ?? '',
          data['recordedBy'] ?? '',
        ]);
      }
      return const ListToCsvConverter().convert(csvData);
    } catch (e) {
      AppLogger.error('Error exporting payments to CSV', e);
      rethrow;
    }
  }

  @override
  Future<String> exportUserSummaryToCsv() async {
    try {
      final summary = await getUserPaymentSummary();
      final csvData = <List<dynamic>>[
        [
          'Name',
          'Email',
          'Total Amount',
          'Months Paid',
          'Last Payment',
          'Current Month Status',
        ],
      ];
      for (final user in summary) {
        csvData.add([
          user['name'],
          user['email'],
          user['totalAmount'].toString(),
          user['monthsPaid'].toString(),
          user['lastPayment'] ?? 'Never',
          user['isCurrentMonth'] ? 'Paid' : 'Not Paid',
        ]);
      }
      return const ListToCsvConverter().convert(csvData);
    } catch (e) {
      AppLogger.error('Error exporting user summary to CSV', e);
      rethrow;
    }
  }
}
