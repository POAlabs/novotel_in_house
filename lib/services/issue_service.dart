import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';

/// Service for managing issues in Firestore
/// Handles CRUD operations for the 'issues' collection
class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
    return _issuesCollection
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  /// Get all issues (for admins) as a stream
  Stream<List<IssueModel>> getAllIssues() {
    return _issuesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  /// Get issues by department as a stream
  /// Users can only see issues assigned to their department
  Stream<List<IssueModel>> getIssuesByDepartment(String department) {
    return _issuesCollection
        .where('department', isEqualTo: department)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  /// Get ongoing issues by department
  Stream<List<IssueModel>> getOngoingIssuesByDepartment(String department) {
    return _issuesCollection
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  /// Get issues reported by a specific user
  Stream<List<IssueModel>> getIssuesReportedByUser(String userId) {
    return _issuesCollection
        .where('reportedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
  }

  /// Get issues for a specific floor
  Stream<List<IssueModel>> getIssuesByFloor(String floor) {
    return _issuesCollection
        .where('floor', isEqualTo: floor)
        .where('status', isEqualTo: 'Ongoing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueModel.fromFirestore(doc))
            .toList());
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
    final doc = await _issuesCollection.doc(issueId).get();
    if (doc.exists) {
      return IssueModel.fromFirestore(doc);
    }
    return null;
  }

  /// Get count of ongoing issues by department
  Future<int> getOngoingIssueCount(String department) async {
    final snapshot = await _issuesCollection
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: 'Ongoing')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get count of all ongoing issues
  Future<int> getTotalOngoingIssueCount() async {
    final snapshot = await _issuesCollection
        .where('status', isEqualTo: 'Ongoing')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
