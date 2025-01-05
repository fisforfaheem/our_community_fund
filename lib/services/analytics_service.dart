import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to handle analytics errors
  Future<void> _logEvent(Future<void> Function() event) async {
    try {
      await event();
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error: $e');
      }
    }
  }

  // Get payment statistics for a specific time range
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

  // User Events
  Future<void> logUserLogin() async {
    await _analytics.logLogin();
  }

  Future<void> logUserRegistration() async {
    await _analytics.logSignUp(signUpMethod: 'email');
  }

  Future<void> logProfileUpdate() async {
    await _analytics.logEvent(name: 'profile_update');
  }

  // Payment Events
  Future<void> logPaymentRecorded({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    await _analytics.logEvent(
      name: 'payment_recorded',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logPaymentReminder({
    required String userId,
    required String reminderType,
  }) async {
    await _analytics.logEvent(
      name: 'payment_reminder_sent',
      parameters: {
        'user_id': userId,
        'reminder_type': reminderType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Support Program Events
  Future<void> logSupportRequest({
    required String userId,
    required String programId,
    required double requestedAmount,
  }) async {
    await _analytics.logEvent(
      name: 'support_request_submitted',
      parameters: {
        'user_id': userId,
        'program_id': programId,
        'requested_amount': requestedAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logSupportRequestReviewed({
    required String requestId,
    required String reviewerId,
    required String status,
  }) async {
    await _analytics.logEvent(
      name: 'support_request_reviewed',
      parameters: {
        'request_id': requestId,
        'reviewer_id': reviewerId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Navigation Events
  Future<void> logScreenView({
    required String screenName,
    required String screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Error Events
  Future<void> logError({
    required String errorCode,
    required String errorMessage,
    required String errorDetails,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage,
        'error_details': errorDetails,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Feature Usage Events
  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) async {
    final params = {
      'feature_name': featureName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalParams,
    };

    await _analytics.logEvent(
      name: 'feature_used',
      parameters: params as Map<String, Object>?,
    );
  }

  // User Session Events
  Future<void> logSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
  }

  Future<void> logSessionEnd() async {
    await _analytics.logEvent(name: 'session_end');
  }
}
