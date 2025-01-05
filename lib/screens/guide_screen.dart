import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Guide'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildUserGuideSection(context),
          const SizedBox(height: 24),
          _buildAdminGuideSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '👋 Welcome to Our Community Fund!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'This guide will help you understand how to use the app effectively.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGuideSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, size: 28),
                SizedBox(width: 8),
                Text(
                  'For Members',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideItem(
              '📱 Dashboard',
              'View your payment status, total contributions, and payment history on your home screen.',
            ),
            _buildGuideItem(
              '💰 Payments',
              'Track your monthly payments and view your contribution history with detailed analytics.',
            ),
            _buildGuideItem(
              '🔔 Notifications',
              'Customize your notification preferences:\n'
                  '• Payment reminders\n'
                  '• Payment confirmations\n'
                  '• System updates\n'
                  '• Email notifications',
            ),
            _buildGuideItem(
              '📊 Analytics',
              'View your payment trends and contribution statistics with interactive charts.',
            ),
            _buildGuideItem(
              '👤 Profile Management',
              'Update your profile and manage notification preferences in settings.',
            ),
            _buildGuideItem(
              '📊 Status',
              'Your payment status is color-coded:\n'
                  '🟢 Green: Up to date\n'
                  '🔴 Yellow: Partial payment\n'
                  '🔴 Red: Payment required',
            ),
            _buildGuideItem(
              '🤝 Community Support',
              'Access community support features:\n'
                  '• View available support programs\n'
                  '• Submit support requests\n'
                  '• Track request status\n'
                  '• View support history',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminGuideSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 28),
                SizedBox(width: 8),
                Text(
                  'For Administrators',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideItem(
              '📊 Enhanced Analytics',
              'Access detailed analytics including:\n'
                  '• Payment trend charts\n'
                  '• Member compliance rates\n'
                  '• Monthly analysis\n'
                  '• Interactive visualizations',
            ),
            _buildGuideItem(
              '💳 Recording Payments',
              'To record a payment:\n'
                  '1. Click the + button\n'
                  '2. Select member\n'
                  '3. Enter amount\n'
                  '4. Add optional note\n'
                  '5. Confirm payment',
            ),
            _buildGuideItem(
              '📈 Reports & Exports',
              'Generate and export:\n'
                  '• Monthly summaries\n'
                  '• Payment trends\n'
                  '• Member compliance rates\n'
                  '• User lists\n'
                  '• Payment history',
            ),
            _buildGuideItem(
              '👥 Member Management',
              '• View and search members\n'
                  '• Check payment status\n'
                  '• Send payment reminders\n'
                  '• View individual histories\n'
                  '• Manage notification settings',
            ),
            _buildGuideItem(
              '⚙️ System Settings',
              'Configure:\n'
                  '• Standard payment amount\n'
                  '• Due dates\n'
                  '• Grace periods\n'
                  '• Notification preferences\n'
                  '• Email notifications',
            ),
            _buildGuideItem(
              '🤝 Community Support Management',
              'Manage support programs:\n'
                  '• Review support requests\n'
                  '• Allocate funds\n'
                  '• Track support disbursements\n'
                  '• Generate support reports\n'
                  '• Monitor program effectiveness',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
