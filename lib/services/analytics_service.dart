import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';

/// Service for computing analytics data from Firestore
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  CollectionReference<Map<String, dynamic>> get _issuesCollection =>
      _firestore.collection('issues');

  /// Get analytics data for a date range
  /// If [department] is null, returns all data (for system admins)
  /// If [department] is provided, filters to that department only
  Future<AnalyticsData> getAnalyticsData({
    String? department,
    required int days,
  }) async {
    debugPrint('📊 [ANALYTICS] getAnalyticsData(dept: $department, days: $days)');

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final previousPeriodStart = startDate.subtract(Duration(days: days));

      // Build query
      Query<Map<String, dynamic>> query = _issuesCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

      if (department != null) {
        query = query.where('department', isEqualTo: department);
      }

      // Fetch current period issues
      final snapshot = await query.get();
      final issues = snapshot.docs;

      // Fetch previous period issues for comparison
      Query<Map<String, dynamic>> prevQuery = _issuesCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousPeriodStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(startDate));

      if (department != null) {
        prevQuery = prevQuery.where('department', isEqualTo: department);
      }

      final prevSnapshot = await prevQuery.get();
      final previousPeriodTotal = prevSnapshot.docs.length;

      // Process current period data
      int totalIssues = issues.length;
      int resolvedIssues = 0;
      int pendingIssues = 0;
      double totalResolutionTime = 0;
      int resolvedCount = 0;

      final Map<String, int> issuesByFloor = {};
      final Map<String, int> issuesByDepartment = {};
      final Map<String, int> issuesByPriority = {};
      final Map<String, List<double>> resolutionTimesByPriority = {};
      final Map<String, int> dailyCounts = {};

      // Initialize daily counts for each day in range
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: days - 1 - i));
        final dateKey = _dateKey(date);
        dailyCounts[dateKey] = 0;
      }

      for (final doc in issues) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'Ongoing';
        final floor = data['floor'] as String? ?? 'Unknown';
        final dept = data['department'] as String? ?? 'Unknown';
        final priority = data['priority'] as String? ?? 'Medium';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;

        // Count by status
        if (status == 'Completed') {
          resolvedIssues++;
          
          // Calculate resolution time
          final resolvedAt = (data['resolvedAt'] as Timestamp?)?.toDate();
          if (resolvedAt != null) {
            final resolutionHours = resolvedAt.difference(createdAt).inMinutes / 60.0;
            totalResolutionTime += resolutionHours;
            resolvedCount++;

            // Track resolution time by priority
            resolutionTimesByPriority.putIfAbsent(priority, () => []);
            resolutionTimesByPriority[priority]!.add(resolutionHours);
          }
        } else {
          pendingIssues++;
        }

        // Count by floor
        issuesByFloor[floor] = (issuesByFloor[floor] ?? 0) + 1;

        // Count by department
        issuesByDepartment[dept] = (issuesByDepartment[dept] ?? 0) + 1;

        // Count by priority
        issuesByPriority[priority] = (issuesByPriority[priority] ?? 0) + 1;

        // Count by day
        final dateKey = _dateKey(createdAt);
        if (dailyCounts.containsKey(dateKey)) {
          dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
        }
      }

      // Calculate average resolution time
      final avgResolutionTime = resolvedCount > 0 
          ? totalResolutionTime / resolvedCount 
          : 0.0;

      // Calculate average resolution time by priority
      final Map<String, double> resolutionTimeByPriority = {};
      for (final entry in resolutionTimesByPriority.entries) {
        if (entry.value.isNotEmpty) {
          resolutionTimeByPriority[entry.key] = 
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      // Convert daily counts to list
      final List<DailyIssueCount> dailyIssueCounts = [];
      final sortedKeys = dailyCounts.keys.toList()..sort();
      for (final key in sortedKeys) {
        final parts = key.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        dailyIssueCounts.add(DailyIssueCount(
          date: date,
          count: dailyCounts[key] ?? 0,
        ));
      }

      // Sort floors in logical order
      final sortedFloors = _sortFloors(issuesByFloor);

      debugPrint('✅ [ANALYTICS] Processed $totalIssues issues');

      return AnalyticsData(
        totalIssues: totalIssues,
        resolvedIssues: resolvedIssues,
        pendingIssues: pendingIssues,
        avgResolutionTimeHours: avgResolutionTime,
        issuesByFloor: sortedFloors,
        issuesByDepartment: issuesByDepartment,
        issuesByPriority: issuesByPriority,
        dailyIssueCounts: dailyIssueCounts,
        resolutionTimeByPriority: resolutionTimeByPriority,
        previousPeriodTotal: previousPeriodTotal,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ANALYTICS] Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return AnalyticsData.empty();
    }
  }

  /// Generate date key for grouping (YYYY-MM-DD)
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Sort floors in logical order (B3, B2, B1, G, 1, 2, ..., 11)
  Map<String, int> _sortFloors(Map<String, int> floors) {
    final entries = floors.entries.toList();
    entries.sort((a, b) => _floorValue(a.key).compareTo(_floorValue(b.key)));
    return Map.fromEntries(entries);
  }

  int _floorValue(String floor) {
    if (floor == 'G') return 0;
    if (floor.startsWith('B')) {
      return -int.parse(floor.substring(1));
    }
    return int.tryParse(floor) ?? 0;
  }
}
