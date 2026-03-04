import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/analytics_model.dart';

/// Summary cards row showing key metrics
/// Total issues, Avg resolution time, Resolution rate, Change vs previous period
class AnalyticsSummaryCards extends StatelessWidget {
  final AnalyticsData data;

  const AnalyticsSummaryCards({super.key, required this.data});

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Total Issues
        Expanded(
          child: _buildCard(
            value: '${data.totalIssues}',
            label: 'Total',
            icon: Icons.assignment_outlined,
            color: kBlue,
          ),
        ),
        const SizedBox(width: 8),
        // Avg Resolution Time
        Expanded(
          child: _buildCard(
            value: _formatHours(data.avgResolutionTimeHours),
            label: 'Avg Time',
            icon: Icons.timer_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        // Resolution Rate
        Expanded(
          child: _buildCard(
            value: '${data.resolutionRate.toStringAsFixed(0)}%',
            label: 'Resolved',
            icon: Icons.check_circle_outline,
            color: kGreen,
          ),
        ),
        const SizedBox(width: 8),
        // Change vs Previous
        Expanded(
          child: _buildChangeCard(),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard() {
    final change = data.changePercentage;
    final isIncrease = data.issuesIncreased;
    final color = isIncrease ? kRed : kGreen;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final prefix = isIncrease ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            '$prefix${change.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'vs Prior',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '${(hours / 24).toStringAsFixed(1)}d';
    }
  }
}
