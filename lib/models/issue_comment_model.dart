import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment/Update on an issue
/// Stored in Firestore subcollection: issues/{issueId}/comments
class IssueCommentModel {
  final String id;
  final String comment;
  final String authorId;
  final String authorName;
  final String authorDepartment;
  final DateTime createdAt;
  final String? type; // 'comment', 'reassign', 'priority_change', 'resolved'

  const IssueCommentModel({
    required this.id,
    required this.comment,
    required this.authorId,
    required this.authorName,
    required this.authorDepartment,
    required this.createdAt,
    this.type,
  });

  /// Factory constructor from Firestore document
  factory IssueCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueCommentModel(
      id: doc.id,
      comment: data['comment'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorDepartment: data['authorDepartment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'authorId': authorId,
      'authorName': authorName,
      'authorDepartment': authorDepartment,
      'createdAt': Timestamp.fromDate(createdAt),
      if (type != null) 'type': type,
    };
  }

  /// Smart time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
