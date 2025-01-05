import 'package:flutter/material.dart';
import 'package:our_community_fund/services/reports_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _complianceStats;
  List<Map<String, dynamic>>? _userSummary;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month - 2, 1);
      _endDate = DateTime(now.year, now.month, now.day);

      await _loadData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _reportsService.getPaymentStats(
        startDate: _startDate,
        endDate: _endDate,
      );
      final complianceStats = await _reportsService.getUserComplianceStats();
      final userSummary = await _reportsService.getUserPaymentSummary();

      setState(() {
        _stats = stats;
        _complianceStats = complianceStats;
        _userSummary = userSummary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime(now.year, now.month - 2, 1),
        end: _endDate ?? now,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() => _isLoading = true);

      // Get app directory first to fail fast if there's a permission issue
      final directory =
          await getApplicationDocumentsDirectory().catchError((e) {
        throw Exception('Failed to access app directory: $e');
      });

      // Export payments data
      final paymentsCSV = await _reportsService
          .exportPaymentsToCSV(
        startDate: _startDate,
        endDate: _endDate,
      )
          .catchError((e) {
        throw Exception('Failed to generate payments report: $e');
      });

      // Export user summary
      final userSummaryCSV =
          await _reportsService.exportUserSummaryToCSV().catchError((e) {
        throw Exception('Failed to generate user summary report: $e');
      });

      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

      // Save payment data
      final paymentsFile = File('${directory.path}/payments_$timestamp.csv');
      await paymentsFile.writeAsString(paymentsCSV).catchError((e) {
        throw Exception('Failed to save payments report: $e');
      });

      // Save user summary
      final summaryFile = File('${directory.path}/user_summary_$timestamp.csv');
      await summaryFile.writeAsString(userSummaryCSV).catchError((e) {
        throw Exception('Failed to save user summary report: $e');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reports exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: const Text('Payment Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateRangeCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildComplianceCard(),
            const SizedBox(height: 16),
            _buildMonthlyTrendsCard(),
            const SizedBox(height: 16),
            _buildUserSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectDateRange,
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Amount',
                '\$${_stats!['totalAmount'].toStringAsFixed(2)}'),
            _buildStatRow(
                'Number of Payments', _stats!['paymentCount'].toString()),
            _buildStatRow(
                'Unique Contributors', _stats!['uniqueUsers'].toString()),
            _buildStatRow('Average Payment',
                '\$${_stats!['averagePayment'].toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    if (_complianceStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Compliance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _complianceStats!['compliantUsers'].toDouble(),
                      title: 'Compliant',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: _complianceStats!['partiallyCompliantUsers']
                          .toDouble(),
                      title: 'Partial',
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: _complianceStats!['nonCompliantUsers'].toDouble(),
                      title: 'Non-Compliant',
                      color: Colors.red,
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

  Widget _buildMonthlyTrendsCard() {
    if (_stats == null || _stats!['monthlyTrends'].isEmpty) {
      return const SizedBox.shrink();
    }

    final monthlyTrends = _stats!['monthlyTrends'] as Map<String, double>;
    final sortedMonths = monthlyTrends.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(sortedMonths.length, (index) {
                        return FlSpot(index.toDouble(),
                            monthlyTrends[sortedMonths[index]]!);
                      }),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
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

  Widget _buildUserSummaryCard() {
    if (_userSummary == null || _userSummary!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Payment Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userSummary!.length,
              itemBuilder: (context, index) {
                final user = _userSummary![index];
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(
                      'Months Paid: ${user['monthsPaid']} | Total: \$${user['totalAmount'].toStringAsFixed(2)}'),
                  trailing: Icon(
                    user['isCurrentMonth'] ? Icons.check_circle : Icons.warning,
                    color: user['isCurrentMonth'] ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
