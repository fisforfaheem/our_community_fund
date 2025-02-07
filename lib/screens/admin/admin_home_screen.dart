import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/services/auth_service.dart';
import 'package:our_community_fund/services/payment_service.dart';
import 'package:our_community_fund/services/notification_service.dart';
import 'package:our_community_fund/screens/admin/record_payment_screen.dart';
import 'package:our_community_fund/screens/admin/reports_screen.dart';
import 'package:our_community_fund/screens/admin/payment_schedule_screen.dart';
import 'package:our_community_fund/screens/admin/payment_history_screen.dart';
import 'package:our_community_fund/screens/admin/members_list_screen.dart';
import 'package:our_community_fund/screens/guide_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import 'package:our_community_fund/screens/admin/payment_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:our_community_fund/providers/theme_provider.dart';
import 'package:our_community_fund/screens/admin/payment_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  late final NotificationService _notificationService;
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _selectedTheme = themeProvider.currentThemeName;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _notificationService = await NotificationService.init();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Community Fund',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('payment_requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final pendingCount =
                    snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: IconButton(
                    icon: const Icon(Icons.payment),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaymentRequestsScreen()),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.help_outline,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuideScreen()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => _showSettingsMenu(),
            ),
            IconButton(
              icon: Icon(Icons.logout,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => _showLogoutDialog(),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 80.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('payment_requests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final pendingCount =
                            snapshot.hasData ? snapshot.data!.docs.length : 0;
                        if (pendingCount == 0) return const SizedBox.shrink();

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentRequestsScreen()),
                          ),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_active,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'New Payment Requests',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'You have $pendingCount pending payment ${pendingCount == 1 ? 'request' : 'requests'} to review',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    if (isSmallScreen) ...[
                      _buildRecentActivity(),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      _buildMembersSummary(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildRecentActivity(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildQuickActions(),
                                const SizedBox(height: 16),
                                _buildMembersSummary(),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          label: Row(
            children: [
              Icon(Icons.add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Record Payment',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Row(
            children: [
              Icon(Icons.access_time,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Monthly Overview',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _paymentService.getMonthlyStatsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              final stats = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildModernStatCard(
                      'Total Collections',
                      '\$${(stats['monthlyTotal'] as num).toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      '${(stats['collectionRate'] as num).toStringAsFixed(0)}%',
                      theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    _buildModernStatCard(
                      'Members Paid',
                      '${stats['paidCount']} / ${stats['totalUsers']}',
                      Icons.people,
                      '${(stats['paidCount'] / stats['totalUsers'] * 100).toStringAsFixed(0)}%',
                      theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 16),
                    _buildModernStatCard(
                      'Outstanding',
                      '\$${(stats['outstanding'] as num).toStringAsFixed(2)}',
                      Icons.warning,
                      '${(100 - (stats['collectionRate'] as num)).toStringAsFixed(0)}%',
                      theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    String percentage,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                  icon: Icon(Icons.analytics,
                      size: 20, color: theme.colorScheme.primary),
                  label: Text('View All',
                      style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('payments')
                .orderBy('date', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            color: Colors.white30, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No recent payments',
                          style: TextStyle(color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final isToday = DateTime.now().difference(date).inDays == 0;
                  final isYesterday =
                      DateTime.now().difference(date).inDays == 1;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['userName'] ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${(data['amount'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isToday
                            ? 'Today at ${DateFormat.jm().format(date)}'
                            : isYesterday
                                ? 'Yesterday at ${DateFormat.jm().format(date)}'
                                : DateFormat.yMMMd().add_jm().format(date),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () => _showPaymentDetails(data),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildModernActionButton(
                'Schedule',
                Icons.calendar_month,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PaymentScheduleScreen()),
                ),
              ),
              _buildModernActionButton(
                'Reports',
                Icons.bar_chart,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('payment_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  final pendingCount =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;

                  return Stack(
                    children: [
                      _buildModernActionButton(
                        'Payment Requests',
                        Icons.notifications_active,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentRequestsScreen()),
                        ),
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              _buildModernActionButton(
                'Test Notification',
                Icons.notification_important,
                () => _testNotification(),
              ),
              _buildModernActionButton(
                'Export',
                Icons.download,
                () => _showExportDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          print('Testing notification for user: ${currentUser.uid}');
        }
        await _notificationService.sendTestNotification(currentUser.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test notification sent'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending test notification: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildModernActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    if (label == 'Payment Requests') {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('payment_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          final pendingCount =
              snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          icon,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Members',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => _showAllMembers(),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...users.map((user) => _buildMemberTile(user)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(UserModel user) {
    final hasRecentPayment = user.lastPayment?.month == DateTime.now().month;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  hasRecentPayment ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              hasRecentPayment ? Icons.check_circle : Icons.warning,
              color: hasRecentPayment ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  hasRecentPayment ? 'Paid this month' : 'Payment pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMemberActions(user),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Record Payment'),
              onTap: () {
                Navigator.pop(context);
                _showRecordPaymentScreen(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Send Notification'),
              onTap: () {
                Navigator.pop(context);
                _sendCustomNotification(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Payment History'),
              onTap: () {
                Navigator.pop(context);
                _showPaymentHistory(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentHistoryScreen(user: user),
      ),
    );
  }

  void _showAllMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembersListScreen()),
    );
  }

  void _showSendNotificationDialog() {
    // TODO: Implement send notification dialog
  }

  void _showExportDialog() {
    final exportOptions = [
      {
        'title': 'Payment Records',
        'format': 'CSV',
        'icon': Icons.receipt_long,
        'description': 'All payment transactions',
      },
      {
        'title': 'Member Directory',
        'format': 'CSV',
        'icon': Icons.people,
        'description': 'Complete member list with details',
      },
      {
        'title': 'Financial Reports',
        'format': 'PDF',
        'icon': Icons.analytics,
        'description': 'Monthly collection reports',
      },
      {
        'title': 'Audit Logs',
        'format': 'CSV',
        'icon': Icons.history,
        'description': 'System activity logs',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.download, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            const Text(
              'Export Data',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose data to export',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...exportOptions.map((option) => _buildExportOptionCard(
                  option['title'] as String,
                  option['format'] as String,
                  option['icon'] as IconData,
                  option['description'] as String,
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildExportSettingButton(
                    'Date Range',
                    Icons.date_range,
                    'Last 30 days',
                    () {
                      // TODO: Show date range picker
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExportSettingButton(
                    'Format',
                    Icons.file_present,
                    'CSV',
                    () {
                      // TODO: Show format selector
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              // TODO: Handle data export
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preparing export...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionCard(
    String title,
    String format,
    IconData icon,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  format,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          value: false,
          onChanged: (value) {
            // TODO: Handle export option selection
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildExportSettingButton(
    String title,
    IconData icon,
    String value,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRecordPaymentScreen([UserModel? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordPaymentScreen(selectedUser: user),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment recorded successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _sendCustomNotification(UserModel user) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Send Notification to ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
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
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                await _notificationService.sendNotificationToUser(
                  userId: user.id,
                  title: titleController.text,
                  body: messageController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification sent successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Confirm Logout',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final theme = Theme.of(context);
    final date = (payment['date'] as Timestamp).toDate();
    final dateStr = DateFormat.yMMMd().add_jm().format(date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Payment Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User', payment['userName'] ?? 'Unknown User'),
            _buildDetailRow(
              'Amount',
              '\$${(payment['amount'] as num).toStringAsFixed(2)}',
            ),
            _buildDetailRow('Date', dateStr),
            if (payment['note'] != null &&
                payment['note'].toString().isNotEmpty)
              _buildDetailRow('Note', payment['note'].toString()),
            if (payment['recordedBy'] != null)
              _buildDetailRow('Recorded By', payment['recordedBy']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildSettingsItem(
                'App Theme',
                Icons.palette,
                () {
                  Navigator.pop(context);
                  _showThemeSelector();
                },
              ),
              _buildSettingsItem(
                'Notification Settings',
                Icons.notifications_active,
                () {
                  Navigator.pop(context);
                  _showNotificationSettings();
                },
              ),
              _buildSettingsItem(
                'Payment Rules',
                Icons.rule,
                () {
                  Navigator.pop(context);
                  _showPaymentRules();
                },
              ),
              _buildSettingsItem(
                'Admin Preferences',
                Icons.admin_panel_settings,
                () {
                  Navigator.pop(context);
                  _showAdminPreferences();
                },
              ),
              _buildSettingsItem(
                'Data Management',
                Icons.storage,
                () {
                  Navigator.pop(context);
                  _showDataManagement();
                },
              ),
              _buildSettingsItem(
                'About',
                Icons.info_outline,
                () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }

  void _showThemeSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedTheme = themeProvider.currentThemeName;
    });

    final List<Map<String, dynamic>> themes = [
      {
        'title': 'System Default',
        'icon': Icons.brightness_auto,
        'description': 'Follow system theme settings',
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'title': 'Light Theme',
        'icon': Icons.light_mode,
        'description': 'Clean, bright interface',
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'title': 'Dark Theme',
        'icon': Icons.dark_mode,
        'description': 'Easy on the eyes',
        'color': Theme.of(context).colorScheme.primary,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Choose Theme',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select your preferred app theme',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ...themes.map((theme) => _buildThemeOption(
                  theme['title'] as String,
                  theme['icon'] as IconData,
                  theme['description'] as String,
                  theme['color'] as Color,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await themeProvider.setTheme(_selectedTheme);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Theme updated successfully',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    IconData icon,
    String description,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTheme = title;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedTheme == title
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.1),
                width: _selectedTheme == title ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: title,
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationOption(
              'Payment Reminders',
              'Send reminders to members for pending payments',
              true,
              (value) {
                // TODO: Save to preferences
              },
            ),
            const SizedBox(height: 16),
            _buildNotificationOption(
              'Payment Confirmations',
              'Send confirmation when payment is recorded',
              true,
              (value) {
                // TODO: Save to preferences
              },
            ),
            const SizedBox(height: 16),
            _buildNotificationOption(
              'Monthly Reports',
              'Send monthly collection reports',
              false,
              (value) {
                // TODO: Save to preferences
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Reminder Schedule',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                'Set when to send payment reminders',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReminderSchedule();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    bool initialValue,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      value: initialValue,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
    );
  }

  void _showReminderSchedule() {
    final reminderOptions = [
      {
        'title': '1 day before due date',
        'subtitle': 'Send a friendly reminder',
        'icon': Icons.notification_important,
      },
      {
        'title': 'On due date',
        'subtitle': 'Notify when payment is due',
        'icon': Icons.event,
      },
      {
        'title': '3 days after due date',
        'subtitle': 'Follow up on pending payments',
        'icon': Icons.warning,
      },
      {
        'title': 'Weekly until paid',
        'subtitle': 'Regular reminders for overdue payments',
        'icon': Icons.repeat,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reminder Schedule',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose when to send payment reminders',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...reminderOptions.map((option) => _buildReminderOptionCard(
                  option['title'] as String,
                  option['subtitle'] as String,
                  option['icon'] as IconData,
                )),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Smart Reminders',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically adjust reminder frequency based on payment history',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: true,
              onChanged: (value) {
                // TODO: Handle smart reminders setting
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save reminder schedule
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder schedule updated'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOptionCard(
      String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          value: false,
          onChanged: (value) {
            // TODO: Handle reminder option selection
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showPaymentRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Payment Rules',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentRuleField(
              'Monthly Due Amount',
              '\$100.00',
              TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildPaymentRuleField(
              'Due Date',
              '1st of every month',
              TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildPaymentRuleField(
              'Grace Period (days)',
              '5',
              TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildPaymentRuleField(
              'Late Fee',
              '\$10.00',
              TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Allow Partial Payments',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Members can pay in installments',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: true,
              onChanged: (value) {
                // TODO: Save setting
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save payment rules
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRuleField(
    String label,
    String initialValue,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  void _showAdminPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Admin Preferences',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdminPreferenceOption(
              'Require Approval',
              'Need admin approval for member registrations',
              true,
            ),
            const SizedBox(height: 16),
            _buildAdminPreferenceOption(
              'Auto Notifications',
              'Automatically send notifications for events',
              true,
            ),
            const SizedBox(height: 16),
            _buildAdminPreferenceOption(
              'Analytics Tracking',
              'Track detailed payment analytics',
              true,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: Colors.white70),
              ),
              title: const Text(
                'Admin Permissions',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Manage other admin accounts',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
              onTap: () {
                Navigator.pop(context);
                _showAdminPermissions();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPreferenceOption(
    String title,
    String subtitle,
    bool initialValue,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: initialValue,
      onChanged: (value) {
        // TODO: Save admin preference
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showAdminPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Admin Permissions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPermissionOption('Manage Members', true),
            _buildPermissionOption('Record Payments', true),
            _buildPermissionOption('Send Notifications', true),
            _buildPermissionOption('View Reports', true),
            _buildPermissionOption('Modify Settings', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save permissions
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionOption(String title, bool initialValue) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: initialValue,
      onChanged: (value) {
        // TODO: Handle permission change
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showDataManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Data Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDataManagementTile(
              'Export Data',
              'Download all data as CSV',
              Icons.download,
              () {
                // TODO: Implement data export
                Navigator.pop(context);
                _showExportDialog();
              },
            ),
            _buildDataManagementTile(
              'Backup Settings',
              'Configure automatic backups',
              Icons.backup,
              () {
                // TODO: Implement backup settings
                Navigator.pop(context);
                _showBackupSettings();
              },
            ),
            _buildDataManagementTile(
              'Clear Cache',
              'Clear temporary data',
              Icons.cleaning_services,
              () {
                // TODO: Implement cache clearing
                Navigator.pop(context);
                _showClearCacheConfirmation();
              },
            ),
            _buildDataManagementTile(
              'Delete Data',
              'Permanently delete selected data',
              Icons.delete_forever,
              () {
                // TODO: Implement data deletion
                Navigator.pop(context);
                _showDeleteDataConfirmation();
              },
              isDestructive: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : Colors.white).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.white70,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  void _showBackupSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Backup Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Auto Backup',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically backup data daily',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: true,
              onChanged: (value) {
                // TODO: Handle auto backup setting
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Backup Location',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Choose where to store backups',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.folder, color: Colors.white70),
              onTap: () {
                // TODO: Handle backup location selection
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: Handle manual backup
              },
              icon: const Icon(Icons.backup),
              label: const Text('Backup Now'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will clear all temporary data. This action cannot be undone.',
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
          FilledButton(
            onPressed: () {
              // TODO: Handle cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Data',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. Please type "DELETE" to confirm.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type DELETE',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              // TODO: Handle data deletion
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232731),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white70),
            ),
            const SizedBox(width: 12),
            const Text(
              'About Community Fund',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutSection(
              'Version',
              'v1.0.0 (Build 2024.01)',
              Icons.info_outline,
            ),
            const SizedBox(height: 16),
            _buildAboutSection(
              'Developer',
              'Community Fund Team',
              Icons.code,
            ),
            const SizedBox(height: 16),
            _buildAboutSection(
              'Contact',
              'support@communityfund.com',
              Icons.email,
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Community Fund is a modern payment management system designed to help communities track and manage their funds efficiently. Built with Flutter and Firebase for reliable performance and real-time updates.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAboutButton(
                  'Privacy Policy',
                  Icons.privacy_tip,
                  () {
                    // TODO: Open privacy policy
                  },
                ),
                _buildAboutButton(
                  'Terms of Service',
                  Icons.description,
                  () {
                    // TODO: Open terms of service
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Check for updates
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your app is up to date!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.system_update),
                label: const Text('Check for Updates'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, String content, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                content,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutButton(
      String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
      ),
    );
  }

  void _showExportOptions() {
    _showExportDialog();
  }
}
