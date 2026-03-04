import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

/// Bar chart showing average resolution time by priority
class ResolutionTimeChart extends StatelessWidget {
  final Map<String, double> resolutionTimeByPriority;

  const ResolutionTimeChart({super.key, required this.resolutionTimeByPriority});

  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);

  // Priority colors
  static const Map<String, Color> priorityColors = {
    'Urgent': Color(0xFFDC2626),
    'High': Color(0xFFEA580C),
    'Medium': Color(0xFFF59E0B),
    'Low': Color(0xFFFBBF24),
  };

  // Priority order
  static const List<String> priorityOrder = ['Urgent', 'High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    if (resolutionTimeByPriority.isEmpty) {
      return _buildEmptyState();
    }

    // Order by priority level
    final orderedEntries = priorityOrder
        .where((p) => resolutionTimeByPriority.containsKey(p))
        .map((p) => MapEntry(p, resolutionTimeByPriority[p]!))
        .toList();

    if (orderedEntries.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = orderedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVG RESOLUTION TIME',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final priority = orderedEntries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '$priority\n${_formatHours(rod.toY)}',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= orderedEntries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            orderedEntries[index].key,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: priorityColors[orderedEntries[index].key] ?? kGrey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: maxValue / 3,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatHoursShort(value),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: kGrey,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: orderedEntries.asMap().entries.map((entry) {
                  final priority = entry.value.key;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: priorityColors[priority] ?? kGrey,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)} min';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    } else {
      return '${(hours / 24).toStringAsFixed(1)} days';
    }
  }

  String _formatHoursShort(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(0)}h';
    } else {
      return '${(hours / 24).toStringAsFixed(0)}d';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVG RESOLUTION TIME',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'No resolved issues yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: kGrey,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
