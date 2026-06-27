import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:our_community_fund/domain/use_cases/notification/notification_use_cases.dart';
import 'package:our_community_fund/domain/use_cases/user/get_current_user_use_case.dart';
import 'package:our_community_fund/widgets/common/gradient_background.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final user = await context.read<GetCurrentUserUseCase>().execute();
      if (mounted) {
        setState(() {
          _userId = user.id;
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

  Future<void> _markAsRead(String notificationId) async {
    await context.read<MarkNotificationReadUseCase>().execute(notificationId);
  }

  Future<void> _markAllAsRead() async {
    if (_userId == null) return;
    await context.read<MarkAllNotificationsReadUseCase>().execute(_userId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 20),
                      label: const Text(
                        'Mark all read',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context
                      .read<WatchNotificationsUseCase>()
                      .execute(_userId!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data![index];
                        final isRead = data['read'] as bool? ?? false;
                        final rawTimestamp = data['timestamp'];
                        final timestamp = rawTimestamp is Timestamp
                            ? rawTimestamp.toDate()
                            : DateTime.now();
                        final title = data['title'] as String;
                        final body = data['body'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ModernCard(
                            color: isRead ? null : Colors.blue.withOpacity(0.1),
                            onTap: isRead
                                ? null
                                : () => _markAsRead(data['id'] as String),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        data['type'] == 'payment'
                                            ? Icons.payment
                                            : Icons.notifications,
                                        color: Colors.white70,
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
                                            title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            DateFormat.yMMMd()
                                                .add_jm()
                                                .format(timestamp),
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
