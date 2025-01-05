import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/models/notification_preferences.dart';
import 'package:our_community_fund/services/notification_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  // final _notificationService = NotificationService();
  bool _isLoading = false;
  NotificationPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      // final prefs = await _notificationService.getPreferences(widget.user.id);
      // setState(() => _preferences = prefs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Update user profile
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .update({
          'name': _nameController.text.trim(),
        });

        // Update notification preferences
        if (_preferences != null) {
          // await _notificationService.updatePreferences(_preferences!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isLoading && _preferences == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👤 Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(widget.user.email),
                            tileColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_preferences != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔔 Notification Preferences',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Payment Reminders'),
                              subtitle: const Text(
                                  'Receive monthly payment reminders'),
                              value: _preferences!.paymentReminders,
                              onChanged: (bool value) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(
                                    paymentReminders: value,
                                  );
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Payment Confirmations'),
                              subtitle: const Text(
                                  'Receive payment confirmation notifications'),
                              value: _preferences!.paymentConfirmations,
                              onChanged: (bool value) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(
                                    paymentConfirmations: value,
                                  );
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('System Updates'),
                              subtitle: const Text(
                                  'Receive important system update notifications'),
                              value: _preferences!.systemUpdates,
                              onChanged: (bool value) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(
                                    systemUpdates: value,
                                  );
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Email Notifications'),
                              subtitle: const Text(
                                  'Receive notifications via email as well'),
                              value: _preferences!.emailNotifications,
                              onChanged: (bool value) {
                                setState(() {
                                  _preferences = _preferences!.copyWith(
                                    emailNotifications: value,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
