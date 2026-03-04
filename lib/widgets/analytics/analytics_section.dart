import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/analytics_model.dart';
import '../../services/analytics_service.dart';
import 'summary_cards.dart';
import 'issues_over_time_chart.dart';
import 'issues_by_floor_chart.dart';
import 'issues_by_department_chart.dart';
import 'resolution_time_chart.dart';

/// Main analytics section that assembles all chart components
/// Shows department-filtered data for managers, all data for system admins
class AnalyticsSection extends StatefulWidget {
  /// If null, shows all departments (system admin view)
  /// If provided, filters to that department only (manager view)
  final String? department;
  
  /// Whether to show the department breakdown chart (only for system admins)
  final bool showDepartmentChart;

  const AnalyticsSection({
    super.key,
    this.department,
    this.showDepartmentChart = false,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kBlue = Color(0xFF3B82F6);

  final AnalyticsService _analyticsService = AnalyticsService();
  
  AnalyticsDateRange _selectedRange = AnalyticsDateRange.last30Days;
  AnalyticsData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(AnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.department != widget.department) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await _analyticsService.getAnalyticsData(
      department: widget.department,
      days: _selectedRange.days,
    );
    
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  void _onRangeChanged(AnalyticsDateRange? range) {
    if (range != null && range != _selectedRange) {
      setState(() => _selectedRange = range);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with date range selector
        _buildHeader(),
        const SizedBox(height: 16),
        // Content
        if (_isLoading)
          _buildLoadingState()
        else if (_data != null)
          _buildContent()
        else
          _buildErrorState(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, size: 18, color: kBlue),
            const SizedBox(width: 8),
            Text(
              'ANALYTICS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: kBlue,
              ),
            ),
          ],
        ),
        // Date range dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AnalyticsDateRange>(
              value: _selectedRange,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kGrey),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kDark,
              ),
              items: AnalyticsDateRange.values.map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(range.displayName),
                );
              }).toList(),
              onChanged: _onRangeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(kBlue),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading analytics...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: kGrey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'Unable to load analytics',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadData,
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    
    return Column(
      children: [
        // Summary cards row
        AnalyticsSummaryCards(data: data),
        const SizedBox(height: 12),
        
        // Issues over time chart
        IssuesOverTimeChart(dailyCounts: data.dailyIssueCounts),
        const SizedBox(height: 12),
        
        // Floor and Department charts side by side (or stacked on narrow screens)
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 500 && widget.showDepartmentChart) {
              // Wide screen - side by side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IssuesByFloorChart(issuesByFloor: data.issuesByFloor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IssuesByDepartmentChart(issuesByDepartment: data.issuesByDepartment),
                  ),
                ],
              );
            } else {
              // Narrow screen or no department chart - stack vertically
              return Column(
                children: [
                  IssuesByFloorChart(issuesByFloor: data.issuesByFloor),
                  if (widget.showDepartmentChart) ...[
                    const SizedBox(height: 12),
                    IssuesByDepartmentChart(issuesByDepartment: data.issuesByDepartment),
                  ],
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),
        
        // Resolution time chart
        ResolutionTimeChart(resolutionTimeByPriority: data.resolutionTimeByPriority),
        const SizedBox(height: 24),
      ],
    );
  }
}
