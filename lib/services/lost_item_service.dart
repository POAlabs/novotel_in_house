import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lost_item_model.dart';
import '../models/user_model.dart';
import 'debug_log_service.dart';

/// Service for managing lost and found items in Firestore
class LostItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DebugLogService _debugLog = DebugLogService();

  /// Collection reference
  CollectionReference get _collection => _firestore.collection('lost_items');

  /// Get all unclaimed lost items (real-time stream)
  Stream<List<LostItemModel>> getUnclaimedItems() {
    return _collection
        .where('status', isEqualTo: 'Found')
        .orderBy('foundAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LostItemModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all lost items (real-time stream)
  Stream<List<LostItemModel>> getAllItems() {
    return _collection.orderBy('foundAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => LostItemModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get claimed items history
  Stream<List<LostItemModel>> getClaimedItems() {
    return _collection
        .where('status', isEqualTo: 'Claimed')
        .orderBy('claimedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LostItemModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Report a new found item
  Future<bool> reportFoundItem({
    required String itemName,
    required String description,
    required String location,
    required String floor,
    required UserModel reporter,
    String? imageUrl,
  }) async {
    try {
      final item = LostItemModel(
        id: '', // Will be assigned by Firestore
        itemName: itemName,
        description: description,
        location: location,
        floor: floor,
        status: 'Found',
        foundAt: DateTime.now(),
        foundBy: reporter.uid,
        foundByName: reporter.displayName,
        foundByDepartment: reporter.department,
        imageUrl: imageUrl,
      );

      await _collection.add(item.toFirestore());

      _debugLog.addLog(
        'LostItemService',
        'Lost item reported: $itemName',
        data: {
          'itemName': itemName,
          'floor': floor,
          'location': location,
          'reportedBy': reporter.displayName,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error reporting lost item: $e');
      _debugLog.addLog(
        'LostItemService',
        'Failed to report lost item: $e',
        isError: true,
      );
      return false;
    }
  }

  /// Mark an item as claimed
  Future<bool> markAsClaimed({
    required String itemId,
    required String claimedByName,
    required String claimantContact,
    required UserModel processedBy,
  }) async {
    try {
      await _collection.doc(itemId).update({
        'status': 'Claimed',
        'claimedAt': Timestamp.fromDate(DateTime.now()),
        'claimedBy': processedBy.uid,
        'claimedByName': claimedByName,
        'claimantContact': claimantContact,
      });

      _debugLog.addLog(
        'LostItemService',
        'Lost item claimed',
        data: {
          'itemId': itemId,
          'claimedBy': claimedByName,
          'processedBy': processedBy.displayName,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error marking item as claimed: $e');
      _debugLog.addLog(
        'LostItemService',
        'Failed to mark item as claimed: $e',
        isError: true,
      );
      return false;
    }
  }

  /// Mark an item as disposed (after long unclaimed period)
  Future<bool> markAsDisposed({
    required String itemId,
    required UserModel processedBy,
  }) async {
    try {
      await _collection.doc(itemId).update({'status': 'Disposed'});

      _debugLog.addLog(
        'LostItemService',
        'Lost item disposed',
        data: {'itemId': itemId, 'processedBy': processedBy.displayName},
      );

      return true;
    } catch (e) {
      debugPrint('Error marking item as disposed: $e');
      return false;
    }
  }

  /// Delete a lost item (admin only)
  Future<bool> deleteItem(String itemId) async {
    try {
      await _collection.doc(itemId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting lost item: $e');
      return false;
    }
  }

  /// Search items by name
  Stream<List<LostItemModel>> searchItems(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllItems().map((items) {
      return items.where((item) {
        return item.itemName.toLowerCase().contains(lowerQuery) ||
            item.description.toLowerCase().contains(lowerQuery) ||
            item.location.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }
}
