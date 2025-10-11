import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final UserModel user;

  const PaymentHistoryScreen({super.key, required this.user});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isLoading = false;

  Future<void> _takeScreenshotAndShare() async {
    setState(() => _isLoading = true);

    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File(
                '${tempDir.path}/payment_history_${widget.user.name}_${DateTime.now().millisecondsSinceEpoch}.png')
            .create();
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Payment History for ${widget.user.name} - Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to take screenshot. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History - ${widget.user.name}'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            onPressed: _isLoading ? null : _takeScreenshotAndShare,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B2D5D), // Deep blue
              Color(0xFF1B1E27), // Dark background
            ],
          ),
        ),
        child: RepaintBoundary(
          key: _screenshotKey,
          child: StreamBuilder<QuerySnapshot>(
            stream: _paymentService.getUserPaymentsStream(widget.user.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final payments = snapshot.data!.docs;
              double totalAmount = 0;
              for (var payment in payments) {
                totalAmount +=
                    (payment.data() as Map<String, dynamic>)['amount'] as num;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(totalAmount, payments.length),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment =
                            payments[index].data() as Map<String, dynamic>;
                        final date = (payment['date'] as Timestamp).toDate();
                        final amount = payment['amount'] as num;
                        final note = payment['note'] as String?;
                        final recordedBy = payment['recordedBy'] as String?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.payment,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '\$${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat.yMMMd().format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (note != null && note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Note: $note'),
                                ],
                                if (recordedBy != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recorded by: $recordedBy',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalAmount, int paymentCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Contributions',
                    '\$${totalAmount.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Payments',
                    paymentCount.toString(),
                    Icons.receipt_long,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
