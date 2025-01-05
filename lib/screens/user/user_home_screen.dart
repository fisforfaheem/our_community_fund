import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/models/payment_model.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/services/payment_service.dart';
import 'package:our_community_fund/services/notification_service.dart';
import 'package:our_community_fund/screens/user/notifications_screen.dart';
import 'package:our_community_fund/screens/guide_screen.dart';
import 'package:intl/intl.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  NotificationService? _notificationService;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _unreadNotifications = 0;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    _notificationService = await NotificationService.init();
    await _notificationService?.initialize();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final userDoc =
          await _firestore.collection('users').doc(_currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = UserModel.fromFirestore(userDoc);
        });

        // Check for recent payment
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);

        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: _currentUser.uid)
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .limit(1)
            .get();

        final hasRecentPayment = paymentsSnapshot.docs.isNotEmpty;

        // Schedule monthly reminder if not paid
        if (!hasRecentPayment &&
            _userData != null &&
            _notificationService != null) {
          await _notificationService!.scheduleMonthlyReminder(_userData!);
        }
      }
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUser?.uid)
        .where('read', isEqualTo: false)
        .get();

    if (mounted) {
      setState(() {
        _unreadNotifications = snapshot.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuideScreen(),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  _loadUnreadNotificationsCount();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('users').doc(_currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          final userData = UserModel.fromFirestore(snapshot.data!);
          final hasRecentPayment =
              userData.lastPayment?.month == DateTime.now().month;

          // Schedule monthly reminder if not paid
          if (!hasRecentPayment) {
            _notificationService!.scheduleMonthlyReminder(userData);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              hasRecentPayment ? Colors.green : Colors.red,
                          child: Icon(
                            hasRecentPayment ? Icons.check : Icons.warning,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasRecentPayment
                              ? 'Payment up to date'
                              : 'Payment required',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last payment: ${userData.lastPayment != null ? DateFormat('MMM dd, yyyy').format(userData.lastPayment!) : 'No payments yet'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(userData.name),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(userData.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.monetization_on),
                          title: const Text('Total Contributions'),
                          subtitle: Text(
                              '\$${userData.totalContributions.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment History',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<PaymentModel>>(
                          stream: _paymentService
                              .getUserPayments(_currentUser!.uid),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final payments = snapshot.data ?? [];

                            if (payments.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No payment history'),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                final payment = payments[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.receipt),
                                  ),
                                  title: Text(
                                      '\$${payment.amount.toStringAsFixed(2)}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('MMM dd, yyyy')
                                          .format(payment.date)),
                                      if (payment.note != null)
                                        Text(
                                          payment.note!,
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    'By ${payment.recordedBy}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
