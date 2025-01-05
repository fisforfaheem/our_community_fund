import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get payment statistics
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

      final querySnapshot = await query.get();
      final payments = querySnapshot.docs;

      final totalAmount = payments.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
      );

      final uniqueUsers =
          payments.map((doc) => doc.data()['userId'] as String).toSet().length;

      final averagePayment =
          payments.isEmpty ? 0.0 : totalAmount / payments.length;

      // Calculate monthly trends
      final monthlyTrends = <String, double>{};
      for (var doc in payments) {
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
      if (kDebugMode) {
        print('Error getting payment stats: $e');
      }
      rethrow;
    }
  }

  // Get user compliance statistics
  Future<Map<String, dynamic>> getUserComplianceStats() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      final usersSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();

      int compliantUsers = 0;
      int partiallyCompliantUsers = 0;
      int nonCompliantUsers = 0;

      for (var userDoc in usersSnapshot.docs) {
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

        final currentMonth = now.month;
        final complianceRate = monthsPaid / currentMonth;

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
      if (kDebugMode) {
        print('Error getting user compliance stats: $e');
      }
      rethrow;
    }
  }

  // Get user payment summary
  Future<List<Map<String, dynamic>>> getUserPaymentSummary() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      final usersSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();

      final List<Map<String, dynamic>> summary = [];

      for (var userDoc in usersSnapshot.docs) {
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
      if (kDebugMode) {
        print('Error getting user payment summary: $e');
      }
      rethrow;
    }
  }

  // Export payment data to CSV
  Future<String> exportPaymentsToCSV({
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

      final querySnapshot = await query.get();
      final payments = querySnapshot.docs;

      final List<List<dynamic>> csvData = [
        ['Date', 'User', 'Amount', 'Type', 'Note', 'Recorded By'], // Header
      ];

      for (var doc in payments) {
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
      if (kDebugMode) {
        print('Error exporting payments to CSV: $e');
      }
      rethrow;
    }
  }

  // Export user summary to CSV
  Future<String> exportUserSummaryToCSV() async {
    try {
      final summary = await getUserPaymentSummary();

      final List<List<dynamic>> csvData = [
        [
          'Name',
          'Email',
          'Total Amount',
          'Months Paid',
          'Last Payment',
          'Current Month Status'
        ], // Header
      ];

      for (var user in summary) {
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
      if (kDebugMode) {
        print('Error exporting user summary to CSV: $e');
      }
      rethrow;
    }
  }
}
