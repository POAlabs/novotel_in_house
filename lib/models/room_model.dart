import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Room status enum representing the cleaning workflow states
enum RoomStatus {
  occupied,    // Guest in room (Blue)
  checkout,    // Needs cleaning (Red)
  cleaning,    // Being cleaned (Orange)
  inspection,  // Awaiting supervisor approval (Yellow)
  ready;       // Available for booking (Green)

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.checkout:
        return 'Checkout';
      case RoomStatus.cleaning:
        return 'Cleaning';
      case RoomStatus.inspection:
        return 'Inspection';
      case RoomStatus.ready:
        return 'Ready';
    }
  }

  /// Get color for status
  Color get color {
    switch (this) {
      case RoomStatus.occupied:
        return const Color(0xFF3B82F6); // Blue
      case RoomStatus.checkout:
        return const Color(0xFFEF4444); // Red
      case RoomStatus.cleaning:
        return const Color(0xFFF59E0B); // Orange
      case RoomStatus.inspection:
        return const Color(0xFFEAB308); // Yellow
      case RoomStatus.ready:
        return const Color(0xFF10B981); // Green
    }
  }

  /// Get background color for status (lighter version)
  Color get backgroundColor {
    switch (this) {
      case RoomStatus.occupied:
        return const Color(0xFFEFF6FF); // Light blue
      case RoomStatus.checkout:
        return const Color(0xFFFEF2F2); // Light red
      case RoomStatus.cleaning:
        return const Color(0xFFFFFBEB); // Light orange
      case RoomStatus.inspection:
        return const Color(0xFFFEFCE8); // Light yellow
      case RoomStatus.ready:
        return const Color(0xFFF0FDF4); // Light green
    }
  }

  /// Get border color for status
  Color get borderColor {
    switch (this) {
      case RoomStatus.occupied:
        return const Color(0xFFBFDBFE); // Blue border
      case RoomStatus.checkout:
        return const Color(0xFFFECACA); // Red border
      case RoomStatus.cleaning:
        return const Color(0xFFFDE68A); // Orange border
      case RoomStatus.inspection:
        return const Color(0xFFFEF08A); // Yellow border
      case RoomStatus.ready:
        return const Color(0xFFBBF7D0); // Green border
    }
  }

  /// Convert from string (for Firestore)
  static RoomStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'occupied':
        return RoomStatus.occupied;
      case 'checkout':
        return RoomStatus.checkout;
      case 'cleaning':
        return RoomStatus.cleaning;
      case 'inspection':
        return RoomStatus.inspection;
      case 'ready':
        return RoomStatus.ready;
      default:
        return RoomStatus.ready;
    }
  }

  /// Convert to string (for Firestore)
  String toFirestore() {
    return name;
  }
}

/// Cleaning checklist item definition
class ChecklistItem {
  final String key;
  final String label;
  final String category; // 'bedroom', 'bathroom', 'general'

  const ChecklistItem({
    required this.key,
    required this.label,
    required this.category,
  });
}

/// All checklist items for room cleaning
class CleaningChecklist {
  static const List<ChecklistItem> items = [
    // Bedroom
    ChecklistItem(key: 'bedMade', label: 'Bed made', category: 'bedroom'),
    ChecklistItem(key: 'sheetsChanged', label: 'Sheets changed', category: 'bedroom'),
    ChecklistItem(key: 'dustingDone', label: 'Dusting completed', category: 'bedroom'),
    ChecklistItem(key: 'floorVacuumed', label: 'Floor vacuumed', category: 'bedroom'),
    // Bathroom
    ChecklistItem(key: 'toiletCleaned', label: 'Toilet cleaned & sanitized', category: 'bathroom'),
    ChecklistItem(key: 'showerCleaned', label: 'Shower/tub cleaned', category: 'bathroom'),
    ChecklistItem(key: 'towelsReplaced', label: 'Towels replaced', category: 'bathroom'),
    ChecklistItem(key: 'amenitiesRestocked', label: 'Amenities restocked', category: 'bathroom'),
    // General
    ChecklistItem(key: 'trashEmptied', label: 'Trash emptied', category: 'general'),
    ChecklistItem(key: 'windowsCleaned', label: 'Windows & mirrors cleaned', category: 'general'),
  ];

  /// Get items by category
  static List<ChecklistItem> getByCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  /// Get all checklist keys
  static List<String> get allKeys => items.map((item) => item.key).toList();

  /// Create empty checklist map (all false)
  static Map<String, bool> createEmpty() {
    return {for (var item in items) item.key: false};
  }

  /// Check if all items in checklist are completed
  static bool isComplete(Map<String, bool>? checklist) {
    if (checklist == null) return false;
    for (var item in items) {
      if (checklist[item.key] != true) return false;
    }
    return true;
  }

  /// Get completion count
  static int getCompletedCount(Map<String, bool>? checklist) {
    if (checklist == null) return 0;
    return checklist.values.where((v) => v == true).length;
  }
}

/// Room data model
/// Represents a hotel room with its current cleaning status
class RoomModel {
  final String id;
  final String roomNumber;
  final String floor;
  final RoomStatus status;
  
  // Checkout info (when Front Office marks checkout)
  final DateTime? checkoutAt;
  final String? checkoutBy;
  final String? checkoutByName;
  
  // Cleaning info
  final DateTime? cleaningStartedAt;
  final String? cleaningStartedBy;
  final String? cleaningStartedByName;
  final DateTime? cleaningCompletedAt;
  final Map<String, bool>? checklist;
  
  // Inspection/approval info
  final DateTime? inspectionApprovedAt;
  final String? inspectionApprovedBy;
  final String? inspectionApprovedByName;
  final String? rejectionNote; // If supervisor rejects
  
  // Ready info
  final DateTime? readyAt;
  
  // General
  final DateTime lastUpdated;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.status,
    this.checkoutAt,
    this.checkoutBy,
    this.checkoutByName,
    this.cleaningStartedAt,
    this.cleaningStartedBy,
    this.cleaningStartedByName,
    this.cleaningCompletedAt,
    this.checklist,
    this.inspectionApprovedAt,
    this.inspectionApprovedBy,
    this.inspectionApprovedByName,
    this.rejectionNote,
    this.readyAt,
    required this.lastUpdated,
  });

  /// Get time in current status
  String get timeInStatus {
    DateTime? statusStartTime;
    switch (status) {
      case RoomStatus.checkout:
        statusStartTime = checkoutAt;
        break;
      case RoomStatus.cleaning:
        statusStartTime = cleaningStartedAt;
        break;
      case RoomStatus.inspection:
        statusStartTime = cleaningCompletedAt;
        break;
      case RoomStatus.ready:
        statusStartTime = readyAt ?? inspectionApprovedAt;
        break;
      case RoomStatus.occupied:
        statusStartTime = lastUpdated;
        break;
    }

    if (statusStartTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(statusStartTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Check if checklist is complete
  bool get isChecklistComplete => CleaningChecklist.isComplete(checklist);

  /// Get checklist progress (e.g., "7/10")
  String get checklistProgress {
    final completed = CleaningChecklist.getCompletedCount(checklist);
    final total = CleaningChecklist.items.length;
    return '$completed/$total';
  }

  /// Factory constructor from Firestore document
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      roomNumber: data['roomNumber'] ?? '',
      floor: data['floor'] ?? '',
      status: RoomStatus.fromString(data['status'] ?? 'ready'),
      checkoutAt: (data['checkoutAt'] as Timestamp?)?.toDate(),
      checkoutBy: data['checkoutBy'],
      checkoutByName: data['checkoutByName'],
      cleaningStartedAt: (data['cleaningStartedAt'] as Timestamp?)?.toDate(),
      cleaningStartedBy: data['cleaningStartedBy'],
      cleaningStartedByName: data['cleaningStartedByName'],
      cleaningCompletedAt: (data['cleaningCompletedAt'] as Timestamp?)?.toDate(),
      checklist: data['checklist'] != null
          ? Map<String, bool>.from(data['checklist'])
          : null,
      inspectionApprovedAt: (data['inspectionApprovedAt'] as Timestamp?)?.toDate(),
      inspectionApprovedBy: data['inspectionApprovedBy'],
      inspectionApprovedByName: data['inspectionApprovedByName'],
      rejectionNote: data['rejectionNote'],
      readyAt: (data['readyAt'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'roomNumber': roomNumber,
      'floor': floor,
      'status': status.toFirestore(),
      if (checkoutAt != null) 'checkoutAt': Timestamp.fromDate(checkoutAt!),
      if (checkoutBy != null) 'checkoutBy': checkoutBy,
      if (checkoutByName != null) 'checkoutByName': checkoutByName,
      if (cleaningStartedAt != null) 'cleaningStartedAt': Timestamp.fromDate(cleaningStartedAt!),
      if (cleaningStartedBy != null) 'cleaningStartedBy': cleaningStartedBy,
      if (cleaningStartedByName != null) 'cleaningStartedByName': cleaningStartedByName,
      if (cleaningCompletedAt != null) 'cleaningCompletedAt': Timestamp.fromDate(cleaningCompletedAt!),
      if (checklist != null) 'checklist': checklist,
      if (inspectionApprovedAt != null) 'inspectionApprovedAt': Timestamp.fromDate(inspectionApprovedAt!),
      if (inspectionApprovedBy != null) 'inspectionApprovedBy': inspectionApprovedBy,
      if (inspectionApprovedByName != null) 'inspectionApprovedByName': inspectionApprovedByName,
      if (rejectionNote != null) 'rejectionNote': rejectionNote,
      if (readyAt != null) 'readyAt': Timestamp.fromDate(readyAt!),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create a copy with updated fields
  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? floor,
    RoomStatus? status,
    DateTime? checkoutAt,
    String? checkoutBy,
    String? checkoutByName,
    DateTime? cleaningStartedAt,
    String? cleaningStartedBy,
    String? cleaningStartedByName,
    DateTime? cleaningCompletedAt,
    Map<String, bool>? checklist,
    DateTime? inspectionApprovedAt,
    String? inspectionApprovedBy,
    String? inspectionApprovedByName,
    String? rejectionNote,
    DateTime? readyAt,
    DateTime? lastUpdated,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      checkoutAt: checkoutAt ?? this.checkoutAt,
      checkoutBy: checkoutBy ?? this.checkoutBy,
      checkoutByName: checkoutByName ?? this.checkoutByName,
      cleaningStartedAt: cleaningStartedAt ?? this.cleaningStartedAt,
      cleaningStartedBy: cleaningStartedBy ?? this.cleaningStartedBy,
      cleaningStartedByName: cleaningStartedByName ?? this.cleaningStartedByName,
      cleaningCompletedAt: cleaningCompletedAt ?? this.cleaningCompletedAt,
      checklist: checklist ?? this.checklist,
      inspectionApprovedAt: inspectionApprovedAt ?? this.inspectionApprovedAt,
      inspectionApprovedBy: inspectionApprovedBy ?? this.inspectionApprovedBy,
      inspectionApprovedByName: inspectionApprovedByName ?? this.inspectionApprovedByName,
      rejectionNote: rejectionNote ?? this.rejectionNote,
      readyAt: readyAt ?? this.readyAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'RoomModel(roomNumber: $roomNumber, floor: $floor, status: ${status.displayName})';
  }
}
