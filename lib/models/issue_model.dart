/// Issue data model
/// Represents a reported facility issue
class IssueModel {
  final String id;
  final String floor;
  final String area;
  final String description;
  final String status;
  final String priority;
  final String department;
  final String timeAgo;
  final DateTime timestamp;

  const IssueModel({
    required this.id,
    required this.floor,
    required this.area,
    required this.description,
    required this.status,
    required this.priority,
    required this.department,
    required this.timeAgo,
    required this.timestamp,
  });

  /// Check if issue is ongoing
  bool get isOngoing => status == 'Ongoing';

  /// Check if issue is high priority
  bool get isHighPriority =>
      priority == 'Urgent' || priority == 'High';

  /// Factory constructor for JSON deserialization
  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as String,
      floor: json['floor'] as String,
      area: json['area'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      department: json['department'] as String,
      timeAgo: json['timeAgo'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
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
      'timeAgo': timeAgo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
