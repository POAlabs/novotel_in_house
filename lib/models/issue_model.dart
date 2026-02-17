import 'package:cloud_firestore/cloud_firestore.dart';

/// Issue data model
/// Represents a reported facility issue stored in Firestore
class IssueModel {
  final String id;
  final String floor;
  final String area;
  final String description;
  final String status; // 'Ongoing' or 'Completed'
  final String priority; // 'Urgent', 'High', 'Medium', 'Low'
  final String department; // Target department to handle the issue
  final DateTime createdAt;
  
  // Reporter information
  final String reportedBy; // User UID
  final String reportedByName;
  final String reportedByDepartment;
  
  // Resolution information (nullable)
  final DateTime? resolvedAt;
  final String? resolvedBy; // User UID who resolved
  final String? resolvedByName;
  final String? resolutionNotes;

  const IssueModel({
    required this.id,
    required this.floor,
    required this.area,
    required this.description,
    required this.status,
    required this.priority,
    required this.department,
    required this.createdAt,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedByDepartment,
    this.resolvedAt,
    this.resolvedBy,
    this.resolvedByName,
    this.resolutionNotes,
  });

  /// Check if issue is ongoing
  bool get isOngoing => status == 'Ongoing';

  /// Check if issue is completed
  bool get isCompleted => status == 'Completed';

  /// Check if issue is high priority
  bool get isHighPriority => priority == 'Urgent' || priority == 'High';

  ///Convert to smart time
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

  /// For backwards compatibility
  DateTime get timestamp => createdAt;

  /// Factory constructor from Firestore document
  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      floor: data['floor'] ?? '',
      area: data['area'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Ongoing',
      priority: data['priority'] ?? 'Medium',
      department: data['department'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'] ?? '',
      reportedByName: data['reportedByName'] ?? '',
      reportedByDepartment: data['reportedByDepartment'] ?? '',
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'],
      resolvedByName: data['resolvedByName'],
      resolutionNotes: data['resolutionNotes'],
    );
  }

  /// Convert to Firestore map (for creating new issues)
  Map<String, dynamic> toFirestore() {
    return {
      'floor': floor,
      'area': area,
      'description': description,
      'status': status,
      'priority': priority,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedByDepartment': reportedByDepartment,
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolvedByName != null) 'resolvedByName': resolvedByName,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    };
  }

  /// Create a copy with updated fields
  IssueModel copyWith({
    String? id,
    String? floor,
    String? area,
    String? description,
    String? status,
    String? priority,
    String? department,
    DateTime? createdAt,
    String? reportedBy,
    String? reportedByName,
    String? reportedByDepartment,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolvedByName,
    String? resolutionNotes,
  }) {
    return IssueModel(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedByDepartment: reportedByDepartment ?? this.reportedByDepartment,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  /// Factory constructor for JSON deserialization (legacy support)
  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as String,
      floor: json['floor'] as String,
      area: json['area'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      department: json['department'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['timestamp'] as String),
      reportedBy: json['reportedBy'] ?? '',
      reportedByName: json['reportedByName'] ?? '',
      reportedByDepartment: json['reportedByDepartment'] ?? '',
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt'] as String) 
          : null,
      resolvedBy: json['resolvedBy'],
      resolvedByName: json['resolvedByName'],
      resolutionNotes: json['resolutionNotes'],
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'area': area,
      'description': description,
      'status': status,
      'priority': priority,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedByDepartment': reportedByDepartment,
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolvedByName != null) 'resolvedByName': resolvedByName,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    };
  }
}
