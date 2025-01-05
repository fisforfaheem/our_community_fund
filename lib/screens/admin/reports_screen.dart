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
  String _selectedTimeframe = 'Monthly';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Financial Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white70),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white70),
            onPressed: _exportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildTimeframeSelector(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    _buildComplianceInsights(),
                    const SizedBox(height: 24),
                    _buildTopContributors(),
                    const SizedBox(height: 24),
                    _buildPaymentTrends(),
                    const SizedBox(height: 24),
                    _buildCollectionEfficiency(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStats() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Insights',
                style: TextStyle(
                  color: Colors.white70,
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
            color: Colors.black26,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModernStatCard(
                  'Total Collections',
                  '\$${_stats!['totalAmount'].toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  '${((_stats!['totalAmount'] / (_stats!['targetAmount'] ?? 1) * 100)).toStringAsFixed(0)}%',
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildModernStatCard(
                  'Active Members',
                  '${_stats!['uniqueUsers']}',
                  Icons.people,
                  '${(_stats!['uniqueUsers'] / (_stats!['totalUsers'] ?? 1) * 100).toStringAsFixed(0)}%',
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildModernStatCard(
                  'Average Payment',
                  '\$${_stats!['averagePayment'].toStringAsFixed(2)}',
                  Icons.trending_up,
                  '+${((_stats!['averagePayment'] / (_stats!['previousAveragePayment'] ?? 1) - 1) * 100).toStringAsFixed(0)}%',
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildModernStatCard(
                  'Collection Rate',
                  '${(_complianceStats?['complianceRate'] ?? 0).toStringAsFixed(0)}%',
                  Icons.speed,
                  'Target: 100%',
                  Colors.purple,
                ),
              ],
            ),
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
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                  color: accentColor.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.1),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeframeButton('Weekly'),
          _buildTimeframeButton('Monthly'),
          _buildTimeframeButton('Quarterly'),
          _buildTimeframeButton('Yearly'),
        ],
      ),
    );
  }

  Widget _buildTimeframeButton(String timeframe) {
    final isSelected = _selectedTimeframe == timeframe;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedTimeframe = timeframe;
          // TODO: Update data based on timeframe
        });
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        timeframe,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_stats == null || _stats!['monthlyTrends'].isEmpty) {
      return const SizedBox.shrink();
    }

    final monthlyTrends = _stats!['monthlyTrends'] as Map<String, double>;
    final sortedMonths = monthlyTrends.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Revenue Trends',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedMonths.length) {
                          final month = sortedMonths[value.toInt()]
                              .split('-')[1]; // Get month part
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              month,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(sortedMonths.length, (index) {
                      return FlSpot(index.toDouble(),
                          monthlyTrends[sortedMonths[index]]!);
                    }),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceInsights() {
    if (_complianceStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Compliance Insights',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: _complianceStats!['compliantUsers'].toDouble(),
                          title: 'On Time',
                          color: Colors.green,
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: _complianceStats!['partiallyCompliantUsers']
                              .toDouble(),
                          title: 'Partial',
                          color: Colors.orange,
                          radius: 75,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value:
                              _complianceStats!['nonCompliantUsers'].toDouble(),
                          title: 'Late',
                          color: Colors.red,
                          radius: 70,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComplianceLegendItem(
                      'On Time Payments',
                      _complianceStats!['compliantUsers'],
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildComplianceLegendItem(
                      'Partial Payments',
                      _complianceStats!['partiallyCompliantUsers'],
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildComplianceLegendItem(
                      'Late Payments',
                      _complianceStats!['nonCompliantUsers'],
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopContributors() {
    if (_userSummary == null || _userSummary!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedUsers = List.from(_userSummary!)
      ..sort((a, b) =>
          (b['totalAmount'] as num).compareTo(a['totalAmount'] as num));
    final topUsers = sortedUsers.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Top Contributors',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...topUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTopContributorItem(
                user['name'] as String,
                user['totalAmount'] as num,
                index + 1,
                user['monthsPaid'] as int,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopContributorItem(
      String name, num amount, int rank, int monthsPaid) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$monthsPaid months paid',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Trends',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrendItem(
            'Average Days Late',
            '3.5',
            Icons.timer,
            Colors.orange,
            '-0.5 days from last month',
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'Most Common Payment Day',
            '5th',
            Icons.calendar_today,
            Colors.blue,
            'of each month',
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'Recurring Payments',
            '45%',
            Icons.repeat,
            Colors.green,
            '+5% from last month',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionEfficiency() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Collection Efficiency',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEfficiencyMetric(
            'First Week',
            0.65,
            Colors.green,
            '65% of payments',
          ),
          const SizedBox(height: 16),
          _buildEfficiencyMetric(
            'Second Week',
            0.25,
            Colors.orange,
            '25% of payments',
          ),
          const SizedBox(height: 16),
          _buildEfficiencyMetric(
            'After Due Date',
            0.10,
            Colors.red,
            '10% of payments',
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyMetric(
      String label, double percentage, Color color, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF232731),
                  onSurface: Colors.white,
                ),
            dialogBackgroundColor: const Color(0xFF1B1E27),
          ),
          child: child!,
        );
      },
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

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

      // Export payments data
      final paymentsCSV = await _reportsService.exportPaymentsToCSV(
        startDate: _startDate,
        endDate: _endDate,
      );
      final paymentsFile = File('${directory.path}/payments_$timestamp.csv');
      await paymentsFile.writeAsString(paymentsCSV);

      // Export user summary
      final userSummaryCSV = await _reportsService.exportUserSummaryToCSV();
      final summaryFile = File('${directory.path}/user_summary_$timestamp.csv');
      await summaryFile.writeAsString(userSummaryCSV);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reports exported successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.withOpacity(0.9),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
