import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

/// Pie chart showing issues by department
/// Only visible to system admins
class IssuesByDepartmentChart extends StatefulWidget {
  final Map<String, int> issuesByDepartment;

  const IssuesByDepartmentChart({super.key, required this.issuesByDepartment});

  @override
  State<IssuesByDepartmentChart> createState() => _IssuesByDepartmentChartState();
}

class _IssuesByDepartmentChartState extends State<IssuesByDepartmentChart> {
  int touchedIndex = -1;

  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);

  // Department colors
  static const List<Color> departmentColors = [
    Color(0xFF3B82F6), // Blue - Engineering
    Color(0xFF10B981), // Green - IT
    Color(0xFFF59E0B), // Amber - Housekeeping
    Color(0xFF8B5CF6), // Purple - Front Office
    Color(0xFFEF4444), // Red - Security
    Color(0xFFEC4899), // Pink - F&B
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.issuesByDepartment.isEmpty) {
      return _buildEmptyState();
    }

    final total = widget.issuesByDepartment.values.fold(0, (a, b) => a + b);
    final sortedEntries = widget.issuesByDepartment.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'BY DEPARTMENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sortedEntries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dept = entry.value;
                        final isTouched = index == touchedIndex;
                        final percentage = (dept.value / total) * 100;
                        
                        return PieChartSectionData(
                          color: departmentColors[index % departmentColors.length],
                          value: dept.value.toDouble(),
                          title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
                          radius: isTouched ? 50 : 40,
                          titleStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dept = entry.value;
                    final percentage = (dept.value / total) * 100;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: departmentColors[index % departmentColors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _shortenDeptName(dept.key),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: kDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortenDeptName(String name) {
    switch (name) {
      case 'Engineering': return 'Eng';
      case 'Housekeeping': return 'HK';
      case 'Front Office': return 'FO';
      case 'Security': return 'Sec';
      default: return name;
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
            'BY DEPARTMENT',
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
              'No data available',
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
