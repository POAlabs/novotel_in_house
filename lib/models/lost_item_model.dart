import 'package:cloud_firestore/cloud_firestore.dart';

/// Lost item data model
/// Represents a lost/found item stored in Firestore
class LostItemModel {
  final String id;
  final String itemName;
  final String description;
  final String location; // Where the item was found
  final String floor;
  final String status; // 'Found', 'Claimed', 'Disposed'
  final DateTime foundAt;
  
  // Reporter information
  final String foundBy; // User UID
  final String foundByName;
  final String foundByDepartment;
  
  // Claim information (nullable)
  final DateTime? claimedAt;
  final String? claimedBy;
  final String? claimedByName;
  final String? claimantContact; // Phone or room number
  
  // Optional image
  final String? imageUrl;

  const LostItemModel({
    required this.id,
    required this.itemName,
    required this.description,
    required this.location,
    required this.floor,
    required this.status,
    required this.foundAt,
    required this.foundBy,
    required this.foundByName,
    required this.foundByDepartment,
    this.claimedAt,
    this.claimedBy,
    this.claimedByName,
    this.claimantContact,
    this.imageUrl,
  });

  /// Check if item is still unclaimed
  bool get isUnclaimed => status == 'Found';

  /// Check if item has been claimed
  bool get isClaimed => status == 'Claimed';

  /// Check if item has been disposed
  bool get isDisposed => status == 'Disposed';

  /// Get time since found
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(foundAt);
    
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

  /// Factory constructor from Firestore document
  factory LostItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostItemModel(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      floor: data['floor'] ?? '',
      status: data['status'] ?? 'Found',
      foundAt: (data['foundAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      foundBy: data['foundBy'] ?? '',
      foundByName: data['foundByName'] ?? '',
      foundByDepartment: data['foundByDepartment'] ?? '',
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      claimedBy: data['claimedBy'],
      claimedByName: data['claimedByName'],
      claimantContact: data['claimantContact'],
      imageUrl: data['imageUrl'],
    );
  }

  /// Convert to Firestore map (for creating new items)
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'description': description,
      'location': location,
      'floor': floor,
      'status': status,
      'foundAt': Timestamp.fromDate(foundAt),
      'foundBy': foundBy,
      'foundByName': foundByName,
      'foundByDepartment': foundByDepartment,
      if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
      if (claimedBy != null) 'claimedBy': claimedBy,
      if (claimedByName != null) 'claimedByName': claimedByName,
      if (claimantContact != null) 'claimantContact': claimantContact,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Create a copy with updated fields
  LostItemModel copyWith({
    String? id,
    String? itemName,
    String? description,
    String? location,
    String? floor,
    String? status,
    DateTime? foundAt,
    String? foundBy,
    String? foundByName,
    String? foundByDepartment,
    DateTime? claimedAt,
    String? claimedBy,
    String? claimedByName,
    String? claimantContact,
    String? imageUrl,
  }) {
    return LostItemModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      location: location ?? this.location,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      foundAt: foundAt ?? this.foundAt,
      foundBy: foundBy ?? this.foundBy,
      foundByName: foundByName ?? this.foundByName,
      foundByDepartment: foundByDepartment ?? this.foundByDepartment,
      claimedAt: claimedAt ?? this.claimedAt,
      claimedBy: claimedBy ?? this.claimedBy,
      claimedByName: claimedByName ?? this.claimedByName,
      claimantContact: claimantContact ?? this.claimantContact,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
