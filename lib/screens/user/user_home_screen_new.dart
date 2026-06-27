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
      final user = UserModel.fromEntity(
          await context.read<GetCurrentUserUseCase>().execute());
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
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
                _buildRecentPayments(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Community Fund',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white70),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return ModernCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
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
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                Text(
                  _currentUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return StreamBuilder<User?>(
      stream: context.read<WatchUserDataUseCase>().execute(_currentUser.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lastPayment = snapshot.data?.lastPayment;
        final hasPaidThisMonth = lastPayment != null &&
            lastPayment.month == DateTime.now().month &&
            lastPayment.year == DateTime.now().year;

        return ModernCard(
          color: hasPaidThisMonth
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasPaidThisMonth
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasPaidThisMonth ? Icons.check_circle : Icons.warning,
                      color: hasPaidThisMonth ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPaidThisMonth ? 'Payment Complete' : 'Payment Due',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasPaidThisMonth
                              ? 'Thank you for your payment'
                              : 'Please make your monthly payment',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!hasPaidThisMonth) ...[
                const SizedBox(height: 16),
                ModernButton(
                  label: 'Make Payment',
                  onPressed: () {
                    // TODO: Implement payment flow
                  },
                  icon: Icons.payment,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentPayments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            'Recent Payments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        StreamBuilder<List<Payment>>(
          stream: context
              .read<WatchUserPaymentsUseCase>()
              .execute(_currentUser.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.isEmpty) {
              return ModernCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No payment history yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((payment) {
                return ModernCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Received',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd()
                                  .add_jm()
                                  .format(payment.date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
