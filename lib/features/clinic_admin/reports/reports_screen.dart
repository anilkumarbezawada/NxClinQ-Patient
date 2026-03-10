import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedBarIndex = -1;

  final List<double> _weeklyAppointments = [12, 18, 14, 22, 18, 8, 5];
  final List<double> _monthlyPatients = [20, 28, 35, 30, 42, 38, 50, 45, 55, 60, 52, 68];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.getPrimaryGradient(Theme.of(context).colorScheme.primary)),
        ),
        title: Text('Reports & Analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerTheme.color),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary row
          _SummaryRow(primary: primary),
          const SizedBox(height: 28),

          // Weekly appointments bar chart
          _ChartCard(
            title: "This Week's Appointments",
            subtitle: 'Daily appointment count',
            icon: Icons.bar_chart_rounded,
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 30,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedBarIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} appts',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) => Text(
                          v.toInt().toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= _weekDays.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_weekDays[i], style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: theme.dividerTheme.color ?? Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyAppointments.asMap().entries.map((e) {
                    final isTouch = e.key == _touchedBarIndex;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: isTouch ? AppColors.success : primary.withValues(alpha: 0.75),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Monthly patients line chart
          _ChartCard(
            title: 'New Patients This Year',
            subtitle: 'Monthly registration trend',
            icon: Icons.show_chart_rounded,
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 80,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= _months.length) return const SizedBox.shrink();
                          if (i % 2 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_months[i], style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: theme.dividerTheme.color ?? Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.success,
                      getTooltipItems: (spots) => spots.map((s) {
                        return LineTooltipItem(
                          '${s.y.toInt()} patients',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyPatients.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [AppColors.success.withValues(alpha: 0.2), AppColors.success.withValues(alpha: 0.01)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Specialty breakdown
          _ChartCard(
            title: 'Appointments by Specialty',
            subtitle: 'Top 5 specialties this month',
            icon: Icons.donut_large_rounded,
            child: Column(
              children: [
                _SpecialtyRow('Cardiology', 0.82, AppColors.success, 82),
                _SpecialtyRow('Orthopedics', 0.65, AppColors.primaryBrand, 65),
                _SpecialtyRow('Neurology', 0.48, AppColors.warning, 48),
                _SpecialtyRow('Dermatology', 0.40, AppColors.error, 40),
                _SpecialtyRow('Pediatrics', 0.35, AppColors.info, 35),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Color primary;
  const _SummaryRow({required this.primary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SumItem('Total\nAppointments', '97', Icons.calendar_month_rounded, AppColors.success),
      _SumItem('New\nPatients', '28', Icons.person_add_rounded, primary),
      _SumItem('Revenue\n(Est.)', '₹1.8L', Icons.currency_rupee_rounded, AppColors.warning),
      _SumItem('Avg Wait\nTime', '18 min', Icons.timer_outlined, AppColors.info),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: e.value.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: e.value.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(e.value.icon, color: e.value.color, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    e.value.value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: e.value.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: e.value.color.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SpecialtyRow extends StatelessWidget {
  final String name;
  final double percent;
  final Color color;
  final int count;
  const _SpecialtyRow(this.name, this.percent, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SumItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SumItem(this.label, this.value, this.icon, this.color);
}

