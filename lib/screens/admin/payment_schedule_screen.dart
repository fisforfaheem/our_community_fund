import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentScheduleScreen extends StatefulWidget {
  const PaymentScheduleScreen({super.key});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  // final _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _reminderDayController;
  late TextEditingController _gracePeriodController;
  bool _isLoading = true;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _reminderDayController = TextEditingController();
    _gracePeriodController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('settings').doc('payments').get();
      if (doc.exists) {
        setState(() {
          _settings = doc.data();
          _amountController.text = _settings!['standardAmount'].toString();
          _reminderDayController.text = _settings!['reminderDay'].toString();
          _gracePeriodController.text =
              _settings!['gracePeriodDays'].toString();
        });
      } else {
        // Create default settings
        final defaultSettings = {
          'standardAmount': 50.0,
          'reminderDay': 25,
          'gracePeriodDays': 5,
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        await _firestore
            .collection('settings')
            .doc('payments')
            .set(defaultSettings);
        setState(() {
          _settings = defaultSettings;
          _amountController.text = '50.0';
          _reminderDayController.text = '25';
          _gracePeriodController.text = '5';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedSettings = {
          'standardAmount': double.parse(_amountController.text),
          'reminderDay': int.parse(_reminderDayController.text),
          'gracePeriodDays': int.parse(_gracePeriodController.text),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('settings')
            .doc('payments')
            .update(updatedSettings);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);
    try {
      // Get all non-admin users
      // final users = await _firestore
      //     .collection('users')
      //     .where('isAdmin', isEqualTo: false)
      //     .get();

      // for (var doc in users.docs) {
      //   final user = UserModel.fromFirestore(doc);
      //   await _notificationService.scheduleMonthlyReminder(user);
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notifications sent to all users')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notifications: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Schedule Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Standard Monthly Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reminderDayController,
                        decoration: const InputDecoration(
                          labelText: 'Reminder Day of Month',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a day';
                          }
                          final day = int.tryParse(value);
                          if (day == null) {
                            return 'Please enter a valid number';
                          }
                          if (day < 1 || day > 28) {
                            return 'Day must be between 1 and 28';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gracePeriodController,
                        decoration: const InputDecoration(
                          labelText: 'Grace Period (Days)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of days';
                          }
                          final days = int.tryParse(value);
                          if (days == null) {
                            return 'Please enter a valid number';
                          }
                          if (days < 0 || days > 15) {
                            return 'Grace period must be between 0 and 15 days';
                          }
                          return null;
                        },
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
                        'Notification Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Send Test Notifications'),
                      ),
                      if (_settings?['lastUpdated'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format((_settings!['lastUpdated'] as Timestamp).toDate())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reminderDayController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }
}
