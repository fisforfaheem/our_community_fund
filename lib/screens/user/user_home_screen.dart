import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:our_community_fund/data/models/user_model.dart';
import 'package:our_community_fund/domain/entities/payment.dart';
import 'package:our_community_fund/domain/entities/user.dart';
import 'package:our_community_fund/domain/use_cases/payment/payment_use_cases.dart';
import 'package:our_community_fund/domain/use_cases/user/get_current_user_use_case.dart';
import 'package:our_community_fund/domain/use_cases/user/watch_user_data_use_case.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/screens/user/notifications_screen.dart';
import 'package:our_community_fund/screens/user/profile_edit_screen.dart';
import 'package:our_community_fund/widgets/common/gradient_background.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late UserModel _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user =
          UserModel.fromEntity(await context.read<GetCurrentUserUseCase>().execute());
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ModernButton(
            label: 'Logout',
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthService>().signOut();
            },
            icon: Icons.logout,
          ),
        ],
      ),
    );
  }

  void _showExtraContributionDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isLoading = false;

    void handleContribution() {
      if (isLoading) return;

      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        return;
      }

      setState(() => isLoading = true);
      context.read<RecordExtraContributionUseCase>().execute(
        userId: _currentUser.id,
        amount: amount,
        note: noteController.text.trim(),
      )
          .then((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extra contribution recorded successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() => isLoading = false);
        }
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF232731),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Make Extra Contribution',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernTextField(
                label: 'Amount',
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ModernTextField(
                label: 'Note (Optional)',
                controller: noteController,
                prefixIcon: const Icon(Icons.note),
                // maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ModernButton(
              label: 'Contribute',
              onPressed: handleContribution,
              icon: Icons.add_circle_outline,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifyPaymentButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _showPaymentNotificationDialog(),
        icon: const Icon(Icons.notifications_active),
        label: const Text('Notify Admin About Payment'),
      ),
    );
  }

  void _showPaymentNotificationDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notify Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Payment Details (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Payment method, reference number',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await context.read<SubmitPaymentRequestUseCase>().execute(
                          userId: user.uid,
                          userName: _currentUser.name,
                          amount: double.parse(amountController.text),
                          note: noteController.text,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment notification sent to admin'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Notification'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                const SizedBox(height: 24),
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                _buildPaymentStatus(),
                const SizedBox(height: 24),
                _buildNotifyPaymentButton(),
                const SizedBox(height: 24),
                _buildContributionStats(),
                const SizedBox(height: 24),
                _buildContributionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Community Fund',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.logout,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _currentUser.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus() {
    final theme = Theme.of(context);
    return Column(
      children: [
        StreamBuilder<User?>(
          stream: context
              .read<WatchUserDataUseCase>()
              .execute(_currentUser.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }

            final user = snapshot.data;
            final lastPayment = user?.lastPayment;

            // Check if there's a payment for the current month
            final now = DateTime.now();
            final hasPaidThisMonth = lastPayment != null &&
                lastPayment.year == now.year &&
                lastPayment.month == now.month;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasPaidThisMonth
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          hasPaidThisMonth
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: hasPaidThisMonth
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPaidThisMonth
                                  ? 'Monthly Contribution Complete'
                                  : 'Monthly Contribution Due',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              hasPaidThisMonth
                                  ? 'Thank you for your contribution'
                                  : 'Your monthly contribution is pending',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!hasPaidThisMonth)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              // TODO: Implement payment flow
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Make Contribution'),
                          ),
                        ),
                      if (!hasPaidThisMonth) const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showExtraContributionDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Additional Contribution'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: context
              .read<WatchUserPaymentRequestsUseCase>()
              .execute(_currentUser.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final request = snapshot.data!.first;
            final status = request.status;
            final timestamp = request.timestamp;

            Color statusColor;
            IconData statusIcon;
            String statusText;

            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                statusIcon = Icons.pending;
                statusText = 'Payment notification pending verification';
                break;
              case 'verified':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                statusText = 'Payment verified by admin';
                break;
              case 'rejected':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = 'Payment notification rejected';
                break;
              default:
                return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Notified on ${DateFormat.yMMMd().add_jm().format(timestamp)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'rejected')
                    TextButton(
                      onPressed: _showPaymentNotificationDialog,
                      child: const Text('Try Again'),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContributionStats() {
    final theme = Theme.of(context);
    return StreamBuilder<Map<String, dynamic>>(
      stream: context.read<WatchMonthlyStatsUseCase>().execute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          );
        }

        final stats = snapshot.data!;
        final totalContributed = stats['monthlyTotal'] as double;
        final collectionRate = stats['collectionRate'] as double;

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Community Contributions',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalContributed.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Participation',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${collectionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContributionHistory() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Your Contribution History',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement detailed history view
                },
                icon: Icon(
                  Icons.history,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<Payment>>(
          stream: context
              .read<WatchUserPaymentsUseCase>()
              .execute(_currentUser.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }

            if (snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No contributions yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your contribution history will appear here',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group contributions by month
            final contributions = snapshot.data!.map((payment) {
              return {
                'date': payment.date,
                'amount': payment.amount,
                'isExtra': payment.type == 'extra',
                'note': payment.note,
              };
            }).toList();

            contributions.sort((a, b) =>
                (b['date'] as DateTime).compareTo(a['date'] as DateTime));

            // Group by month
            final groupedContributions = <String, List<Map<String, dynamic>>>{};
            for (var contribution in contributions) {
              final date = contribution['date'] as DateTime;
              final monthKey = DateFormat('MMMM yyyy').format(date);
              groupedContributions.putIfAbsent(monthKey, () => []);
              groupedContributions[monthKey]!.add(contribution);
            }

            return Column(
              children: groupedContributions.entries.map((entry) {
                final monthTotal = entry.value.fold<double>(
                  0,
                  (sum, item) => sum + (item['amount'] as num).toDouble(),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entry.value.length} contribution${entry.value.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '\$${monthTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      ...entry.value.map((contribution) {
                        final date = contribution['date'] as DateTime;
                        final amount = contribution['amount'] as num;
                        final isExtra = contribution['isExtra'] as bool;
                        final note = contribution['note'] as String?;

                        return InkWell(
                          onTap: () {
                            // TODO: Show contribution details
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isExtra
                                        ? theme.colorScheme.tertiary
                                            .withOpacity(0.1)
                                        : theme.colorScheme.primary
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isExtra ? Icons.star : Icons.check_circle,
                                    color: isExtra
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isExtra
                                            ? 'Additional Contribution'
                                            : 'Monthly Contribution',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM d, h:mm a')
                                                .format(date),
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (note != null && note.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          note,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
