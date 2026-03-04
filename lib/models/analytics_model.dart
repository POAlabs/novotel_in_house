/// Analytics data model
/// Holds computed analytics data for the dashboard
class AnalyticsData {
  final int totalIssues;
  final int resolvedIssues;
  final int pendingIssues;
  final double avgResolutionTimeHours;
  final Map<String, int> issuesByFloor;
  final Map<String, int> issuesByDepartment;
  final Map<String, int> issuesByPriority;
  final List<DailyIssueCount> dailyIssueCounts;
  final Map<String, double> resolutionTimeByPriority;
  final int previousPeriodTotal; // For comparison

  const AnalyticsData({
    required this.totalIssues,
    required this.resolvedIssues,
    required this.pendingIssues,
    required this.avgResolutionTimeHours,
    required this.issuesByFloor,
    required this.issuesByDepartment,
    required this.issuesByPriority,
    required this.dailyIssueCounts,
    required this.resolutionTimeByPriority,
    required this.previousPeriodTotal,
  });

  /// Calculate resolution rate as percentage
  double get resolutionRate {
    if (totalIssues == 0) return 100.0;
    return (resolvedIssues / totalIssues) * 100;
  }

  /// Calculate change percentage vs previous period
  double get changePercentage {
    if (previousPeriodTotal == 0) return 0.0;
    return ((totalIssues - previousPeriodTotal) / previousPeriodTotal) * 100;
  }

  /// Check if issues increased vs previous period
  bool get issuesIncreased => totalIssues > previousPeriodTotal;

  /// Empty analytics data
  static AnalyticsData empty() {
    return const AnalyticsData(
      totalIssues: 0,
      resolvedIssues: 0,
      pendingIssues: 0,
      avgResolutionTimeHours: 0,
      issuesByFloor: {},
      issuesByDepartment: {},
      issuesByPriority: {},
      dailyIssueCounts: [],
      resolutionTimeByPriority: {},
      previousPeriodTotal: 0,
    );
  }
}

/// Daily issue count for line chart
class DailyIssueCount {
  final DateTime date;
  final int count;

  const DailyIssueCount({
    required this.date,
    required this.count,
  });

  /// Get short date label (e.g., "Mar 4")
  String get dateLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get day of week label (e.g., "Mon")
  String get dayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

/// Date range options for analytics
enum AnalyticsDateRange {
  last7Days,
  last30Days,
  thisMonth,
  last3Months;

  String get displayName {
    switch (this) {
      case AnalyticsDateRange.last7Days:
        return 'Last 7 Days';
      case AnalyticsDateRange.last30Days:
        return 'Last 30 Days';
      case AnalyticsDateRange.thisMonth:
        return 'This Month';
      case AnalyticsDateRange.last3Months:
        return 'Last 3 Months';
    }
  }

  int get days {
    switch (this) {
      case AnalyticsDateRange.last7Days:
        return 7;
      case AnalyticsDateRange.last30Days:
        return 30;
      case AnalyticsDateRange.thisMonth:
        final now = DateTime.now();
        return now.day;
      case AnalyticsDateRange.last3Months:
        return 90;
    }
  }
}
