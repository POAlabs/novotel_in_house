import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import 'debug_log_service.dart';

/// Service for managing issues in Firestore
/// Handles CRUD operations for the 'issues' collection
class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DebugLogService _debugLog = DebugLogService();
  
  // Collection reference
  CollectionReference<Map<String, dynamic>> get _issuesCollection =>
      _firestore.collection('issues');

  // Singleton instance
  static final IssueService _instance = IssueService._internal();
  factory IssueService() => _instance;
  IssueService._internal();

  /// Create a new issue
  /// Returns the created issue ID
  Future<String> createIssue({
    required String floor,
    required String area,
    required String description,
    required String department,
    required String priority,
    required UserModel reporter,
  }) async {
    final issueData = {
      'floor': floor,
      'area': area,
      'description': description,
      'department': department,
      'priority': priority,
      'status': 'Ongoing',
      'createdAt': Timestamp.now(),
      'reportedBy': reporter.uid,
      'reportedByName': reporter.displayName,
      'reportedByDepartment': reporter.department,
    };

    final docRef = await _issuesCollection.add(issueData);
    return docRef.id;
  }

  /// Get all ongoing issues as a stream
  Stream<List<IssueModel>> getAllOngoingIssues() {
    debugPrint('📝 [ISSUE_SERVICE] getAllOngoingIssues() called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching all ongoing issues',
      data: {'filter': 'status=Ongoing'},
    );
    
    return _issuesCollection
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getAllOngoingIssues received ${issues.length} issues');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received ongoing issues',
            data: {
              'count': issues.length,
              'issueIds': issues.map((i) => i.id).toList(),
            },
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getAllOngoingIssues ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching ongoing issues: $error',
            data: {'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Get all issues (for admins) as a stream
  Stream<List<IssueModel>> getAllIssues() {
    debugPrint('📝 [ISSUE_SERVICE] getAllIssues() called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching all issues (admin)',
    );
    
    return _issuesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getAllIssues received ${issues.length} issues');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received all issues',
            data: {'count': issues.length},
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getAllIssues ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching all issues: $error',
            data: {'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Get issues by department as a stream
  /// Users can only see issues assigned to their department
  Stream<List<IssueModel>> getIssuesByDepartment(String department) {
    debugPrint('📝 [ISSUE_SERVICE] getIssuesByDepartment($department) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching issues by department',
      data: {'department': department},
    );
    
    return _issuesCollection
        .where('department', isEqualTo: department)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getIssuesByDepartment received ${issues.length} issues for $department');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received issues for department',
            data: {'department': department, 'count': issues.length},
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getIssuesByDepartment ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching department issues: $error',
            data: {'department': department, 'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Get ongoing issues by department
  Stream<List<IssueModel>> getOngoingIssuesByDepartment(String department) {
    debugPrint('📝 [ISSUE_SERVICE] getOngoingIssuesByDepartment($department) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching ongoing issues by department',
      data: {'department': department, 'filter': 'status=Ongoing'},
    );
    
    return _issuesCollection
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getOngoingIssuesByDepartment received ${issues.length} issues for $department');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received ongoing issues for department',
            data: {'department': department, 'count': issues.length},
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getOngoingIssuesByDepartment ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching ongoing department issues: $error',
            data: {'department': department, 'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Get issues reported by a specific user
  Stream<List<IssueModel>> getIssuesReportedByUser(String userId) {
    debugPrint('📝 [ISSUE_SERVICE] getIssuesReportedByUser($userId) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching issues reported by user',
      data: {'userId': userId},
    );
    
    return _issuesCollection
        .where('reportedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getIssuesReportedByUser received ${issues.length} issues for user $userId');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received issues for user',
            data: {'userId': userId, 'count': issues.length},
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getIssuesReportedByUser ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching user issues: $error',
            data: {'userId': userId, 'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Get issues for a specific floor
  Stream<List<IssueModel>> getIssuesByFloor(String floor) {
    debugPrint('📝 [ISSUE_SERVICE] getIssuesByFloor($floor) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching issues by floor',
      data: {'floor': floor, 'filter': 'status=Ongoing'},
    );
    
    return _issuesCollection
        .where('floor', isEqualTo: floor)
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final issues = snapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();
          
          debugPrint('✅ [ISSUE_SERVICE] getIssuesByFloor received ${issues.length} issues for floor $floor');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Received issues for floor',
            data: {'floor': floor, 'count': issues.length},
          );
          
          return issues;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ISSUE_SERVICE] getIssuesByFloor ERROR: $error');
          _debugLog.addLog(
            'ISSUE_SERVICE',
            'Error fetching floor issues: $error',
            data: {'floor': floor, 'stackTrace': stackTrace.toString()},
            isError: true,
          );
          throw error;
        });
  }

  /// Mark an issue as resolved
  Future<void> markAsResolved({
    required String issueId,
    required UserModel resolver,
    required String resolutionNotes,
  }) async {
    await _issuesCollection.doc(issueId).update({
      'status': 'Completed',
      'resolvedAt': Timestamp.now(),
      'resolvedBy': resolver.uid,
      'resolvedByName': resolver.displayName,
      'resolutionNotes': resolutionNotes,
    });
  }

  /// Update issue priority
  Future<void> updatePriority({
    required String issueId,
    required String priority,
  }) async {
    await _issuesCollection.doc(issueId).update({
      'priority': priority,
    });
  }

  /// Reassign issue to different department
  Future<void> reassignDepartment({
    required String issueId,
    required String newDepartment,
  }) async {
    await _issuesCollection.doc(issueId).update({
      'department': newDepartment,
    });
  }

  /// Delete an issue (admin only)
  Future<void> deleteIssue(String issueId) async {
    await _issuesCollection.doc(issueId).delete();
  }

  /// Get a single issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    debugPrint('📝 [ISSUE_SERVICE] getIssueById($issueId) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching issue by ID',
      data: {'issueId': issueId},
    );
    
    try {
      final doc = await _issuesCollection.doc(issueId).get();
      if (doc.exists) {
        final issue = IssueModel.fromFirestore(doc);
        debugPrint('✅ [ISSUE_SERVICE] getIssueById found issue: ${issue.description.substring(0, issue.description.length > 30 ? 30 : issue.description.length)}...');
        _debugLog.addLog(
          'ISSUE_SERVICE',
          'Found issue by ID',
          data: {'issueId': issueId, 'floor': issue.floor, 'status': issue.status},
        );
        return issue;
      }
      debugPrint('⚠️ [ISSUE_SERVICE] getIssueById: Issue not found');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Issue not found',
        data: {'issueId': issueId},
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [ISSUE_SERVICE] getIssueById ERROR: $e');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Error fetching issue by ID: $e',
        data: {'issueId': issueId, 'stackTrace': stackTrace.toString()},
        isError: true,
      );
      rethrow;
    }
  }

  /// Get count of ongoing issues by department
  Future<int> getOngoingIssueCount(String department) async {
    debugPrint('📝 [ISSUE_SERVICE] getOngoingIssueCount($department) called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching ongoing issue count for department',
      data: {'department': department},
    );
    
    try {
      final snapshot = await _issuesCollection
          .where('department', isEqualTo: department)
          .where('status', isEqualTo: 'Ongoing')
          .count()
          .get();
      final count = snapshot.count ?? 0;
      
      debugPrint('✅ [ISSUE_SERVICE] getOngoingIssueCount: $count issues for $department');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Got ongoing issue count',
        data: {'department': department, 'count': count},
      );
      
      return count;
    } catch (e, stackTrace) {
      debugPrint('❌ [ISSUE_SERVICE] getOngoingIssueCount ERROR: $e');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Error fetching ongoing issue count: $e',
        data: {'department': department, 'stackTrace': stackTrace.toString()},
        isError: true,
      );
      rethrow;
    }
  }

  /// Get count of all ongoing issues
  Future<int> getTotalOngoingIssueCount() async {
    debugPrint('📝 [ISSUE_SERVICE] getTotalOngoingIssueCount() called');
    _debugLog.addLog(
      'ISSUE_SERVICE',
      'Fetching total ongoing issue count',
    );
    
    try {
      final snapshot = await _issuesCollection
          .where('status', isEqualTo: 'Ongoing')
          .count()
          .get();
      final count = snapshot.count ?? 0;
      
      debugPrint('✅ [ISSUE_SERVICE] getTotalOngoingIssueCount: $count total ongoing issues');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Got total ongoing issue count',
        data: {'count': count},
      );
      
      return count;
    } catch (e, stackTrace) {
      debugPrint('❌ [ISSUE_SERVICE] getTotalOngoingIssueCount ERROR: $e');
      _debugLog.addLog(
        'ISSUE_SERVICE',
        'Error fetching total ongoing issue count: $e',
        data: {'stackTrace': stackTrace.toString()},
        isError: true,
      );
      rethrow;
    }
  }
}
