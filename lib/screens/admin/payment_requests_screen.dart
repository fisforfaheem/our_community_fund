import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/services/payment_service.dart';
import 'package:our_community_fund/services/notification_service.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _paymentService = PaymentService();
  late final Future<NotificationService> _notificationServiceFuture;

  @override
  void initState() {
    super.initState();
    _notificationServiceFuture = NotificationService.init();
  }

  Future<void> _verifyPayment(Map<String, dynamic> request) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();

      // 1. Create payment record
      final payment = PaymentModel(
        id: '',
        userId: request['userId'],
        userName: request['userName'],
        amount: request['amount'],
        date: (request['timestamp'] as Timestamp).toDate(),
        note: request['note'],
        recordedBy: 'Admin (Verified)',
        type: 'regular',
      );

      // 2. Update payment request status
      final requestRef =
          _firestore.collection('payment_requests').doc(request['id']);
      batch.update(requestRef, {'status': 'verified'});

      // 3. Record the payment and commit the batch
      await _paymentService.recordPayment(payment);
      await batch.commit();

      // 4. Send notification to user
      final notificationService = await _notificationServiceFuture;
      await notificationService.sendPaymentConfirmation(
        UserModel(
          id: request['userId'],
          name: request['userName'],
          email: '',
          isAdmin: false,
          totalContributions: 0,
          createdAt: DateTime.now(),
        ),
        request['amount'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying payment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> request) async {
    try {
      await _firestore
          .collection('payment_requests')
          .doc(request['id'])
          .update({'status': 'rejected'});

      // Send rejection notification to user
      final notificationService = await _notificationServiceFuture;
      await notificationService.sendNotificationToUser(
        userId: request['userId'],
        title: 'Payment Request Rejected',
        body:
            'Your payment request of \$${request['amount']} has been rejected. Please contact admin for more information.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment request rejected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting payment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('payment_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment requests',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When users notify about payments, they will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              request['id'] = requests[index].id;
              final timestamp = (request['timestamp'] as Timestamp).toDate();
              final status = request['status'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            request['userName'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${request['amount'].toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request['note']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          request['note'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Notified on ${DateFormat.yMMMd().add_jm().format(timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectPayment(request),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _verifyPayment(request),
                                child: const Text('Verify Payment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    late final Color color;
    late final IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'verified':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
