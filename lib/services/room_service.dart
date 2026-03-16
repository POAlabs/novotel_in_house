import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import 'debug_log_service.dart';

/// Service for managing room cleaning status in Firestore
/// Handles all room status transitions and cleaning workflow operations
class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DebugLogService _debugLog = DebugLogService();

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('rooms');

  // Singleton instance
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  // ─── ROOM QUERIES ──────────────────────────────────────────────────────────

  /// Get all rooms as a stream
  Stream<List<RoomModel>> getAllRooms() {
    debugPrint('📝 [ROOM_SERVICE] getAllRooms() called');
    _debugLog.addLog('ROOM_SERVICE', 'Fetching all rooms');

    return _roomsCollection
        .orderBy('floor')
        .orderBy('roomNumber')
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
          debugPrint('✅ [ROOM_SERVICE] getAllRooms received ${rooms.length} rooms');
          return rooms;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ROOM_SERVICE] getAllRooms ERROR: $error');
          _debugLog.addLog('ROOM_SERVICE', 'Error fetching rooms: $error', isError: true);
          throw error;
        });
  }

  /// Get rooms by floor
  Stream<List<RoomModel>> getRoomsByFloor(String floor) {
    debugPrint('📝 [ROOM_SERVICE] getRoomsByFloor($floor) called');

    return _roomsCollection
        .where('floor', isEqualTo: floor)
        .orderBy('roomNumber')
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
          debugPrint('✅ [ROOM_SERVICE] getRoomsByFloor received ${rooms.length} rooms for floor $floor');
          return rooms;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ROOM_SERVICE] getRoomsByFloor ERROR: $error');
          throw error;
        });
  }

  /// Get rooms by status
  Stream<List<RoomModel>> getRoomsByStatus(RoomStatus status) {
    debugPrint('📝 [ROOM_SERVICE] getRoomsByStatus(${status.displayName}) called');

    return _roomsCollection
        .where('status', isEqualTo: status.toFirestore())
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
          debugPrint('✅ [ROOM_SERVICE] getRoomsByStatus received ${rooms.length} rooms');
          return rooms;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ROOM_SERVICE] getRoomsByStatus ERROR: $error');
          throw error;
        });
  }

  /// Get rooms needing attention (checkout, cleaning, or inspection)
  Stream<List<RoomModel>> getRoomsNeedingAttention() {
    debugPrint('📝 [ROOM_SERVICE] getRoomsNeedingAttention() called');

    return _roomsCollection
        .where('status', whereIn: ['checkout', 'cleaning', 'inspection'])
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
          debugPrint('✅ [ROOM_SERVICE] getRoomsNeedingAttention received ${rooms.length} rooms');
          return rooms;
        })
        .handleError((error, stackTrace) {
          debugPrint('❌ [ROOM_SERVICE] getRoomsNeedingAttention ERROR: $error');
          throw error;
        });
  }

  /// Get a single room by ID
  Future<RoomModel?> getRoomById(String roomId) async {
    debugPrint('📝 [ROOM_SERVICE] getRoomById($roomId) called');

    try {
      final doc = await _roomsCollection.doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] getRoomById ERROR: $e');
      rethrow;
    }
  }

  /// Get a single room by room number
  Future<RoomModel?> getRoomByNumber(String roomNumber) async {
    debugPrint('📝 [ROOM_SERVICE] getRoomByNumber($roomNumber) called');

    try {
      final snapshot = await _roomsCollection
          .where('roomNumber', isEqualTo: roomNumber)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return RoomModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] getRoomByNumber ERROR: $e');
      rethrow;
    }
  }

  /// Stream a single room
  Stream<RoomModel?> streamRoom(String roomId) {
    return _roomsCollection
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? RoomModel.fromFirestore(doc) : null);
  }

  // ─── STATUS TRANSITIONS ────────────────────────────────────────────────────

  /// Mark room as checked out (Front Office only)
  /// OCCUPIED → CHECKOUT
  Future<void> markCheckout({
    required String roomId,
    required UserModel user,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] markCheckout($roomId) called by ${user.displayName}');
    _debugLog.addLog('ROOM_SERVICE', 'Marking room as checkout', data: {
      'roomId': roomId,
      'userId': user.uid,
    });

    try {
      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.checkout.toFirestore(),
        'checkoutAt': Timestamp.now(),
        'checkoutBy': user.uid,
        'checkoutByName': user.displayName,
        'lastUpdated': Timestamp.now(),
        // Clear previous cleaning data
        'cleaningStartedAt': FieldValue.delete(),
        'cleaningStartedBy': FieldValue.delete(),
        'cleaningStartedByName': FieldValue.delete(),
        'cleaningCompletedAt': FieldValue.delete(),
        'checklist': FieldValue.delete(),
        'inspectionApprovedAt': FieldValue.delete(),
        'inspectionApprovedBy': FieldValue.delete(),
        'inspectionApprovedByName': FieldValue.delete(),
        'rejectionNote': FieldValue.delete(),
        'readyAt': FieldValue.delete(),
      });

      debugPrint('✅ [ROOM_SERVICE] Room marked as checkout');
      _debugLog.addLog('ROOM_SERVICE', 'Room marked as checkout successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] markCheckout ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error marking checkout: $e', isError: true);
      rethrow;
    }
  }

  /// Start cleaning a room (Housekeeping staff)
  /// CHECKOUT → CLEANING
  Future<void> startCleaning({
    required String roomId,
    required UserModel user,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] startCleaning($roomId) called by ${user.displayName}');
    _debugLog.addLog('ROOM_SERVICE', 'Starting room cleaning', data: {
      'roomId': roomId,
      'userId': user.uid,
    });

    try {
      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.cleaning.toFirestore(),
        'cleaningStartedAt': Timestamp.now(),
        'cleaningStartedBy': user.uid,
        'cleaningStartedByName': user.displayName,
        'checklist': CleaningChecklist.createEmpty(),
        'lastUpdated': Timestamp.now(),
        // Clear any previous rejection
        'rejectionNote': FieldValue.delete(),
      });

      debugPrint('✅ [ROOM_SERVICE] Room cleaning started');
      _debugLog.addLog('ROOM_SERVICE', 'Room cleaning started successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] startCleaning ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error starting cleaning: $e', isError: true);
      rethrow;
    }
  }

  /// Update checklist item
  Future<void> updateChecklistItem({
    required String roomId,
    required String itemKey,
    required bool value,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] updateChecklistItem($roomId, $itemKey, $value)');

    try {
      await _roomsCollection.doc(roomId).update({
        'checklist.$itemKey': value,
        'lastUpdated': Timestamp.now(),
      });

      debugPrint('✅ [ROOM_SERVICE] Checklist item updated');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] updateChecklistItem ERROR: $e');
      rethrow;
    }
  }

  /// Update entire checklist
  Future<void> updateChecklist({
    required String roomId,
    required Map<String, bool> checklist,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] updateChecklist($roomId)');

    try {
      await _roomsCollection.doc(roomId).update({
        'checklist': checklist,
        'lastUpdated': Timestamp.now(),
      });

      debugPrint('✅ [ROOM_SERVICE] Checklist updated');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] updateChecklist ERROR: $e');
      rethrow;
    }
  }

  /// Complete cleaning and submit for inspection (Housekeeping staff)
  /// CLEANING → INSPECTION
  Future<void> completeCleaning({
    required String roomId,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] completeCleaning($roomId) called');
    _debugLog.addLog('ROOM_SERVICE', 'Completing room cleaning', data: {
      'roomId': roomId,
    });

    try {
      // Verify checklist is complete
      final room = await getRoomById(roomId);
      if (room == null) {
        throw Exception('Room not found');
      }
      if (!room.isChecklistComplete) {
        throw Exception('Checklist is not complete');
      }

      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.inspection.toFirestore(),
        'cleaningCompletedAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });

      debugPrint('✅ [ROOM_SERVICE] Room cleaning completed, awaiting inspection');
      _debugLog.addLog('ROOM_SERVICE', 'Room cleaning completed successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] completeCleaning ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error completing cleaning: $e', isError: true);
      rethrow;
    }
  }

  /// Approve room inspection (Supervisor/Manager only)
  /// INSPECTION → READY
  Future<void> approveRoom({
    required String roomId,
    required UserModel user,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] approveRoom($roomId) called by ${user.displayName}');
    _debugLog.addLog('ROOM_SERVICE', 'Approving room', data: {
      'roomId': roomId,
      'userId': user.uid,
    });

    try {
      final now = Timestamp.now();
      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.ready.toFirestore(),
        'inspectionApprovedAt': now,
        'inspectionApprovedBy': user.uid,
        'inspectionApprovedByName': user.displayName,
        'readyAt': now,
        'lastUpdated': now,
      });

      debugPrint('✅ [ROOM_SERVICE] Room approved and ready');
      _debugLog.addLog('ROOM_SERVICE', 'Room approved successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] approveRoom ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error approving room: $e', isError: true);
      rethrow;
    }
  }

  /// Reject room inspection (Supervisor/Manager only)
  /// INSPECTION → CLEANING (with note)
  Future<void> rejectRoom({
    required String roomId,
    required UserModel user,
    required String rejectionNote,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] rejectRoom($roomId) called by ${user.displayName}');
    _debugLog.addLog('ROOM_SERVICE', 'Rejecting room', data: {
      'roomId': roomId,
      'userId': user.uid,
      'reason': rejectionNote,
    });

    try {
      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.cleaning.toFirestore(),
        'rejectionNote': rejectionNote,
        'lastUpdated': Timestamp.now(),
        // Clear inspection approval data
        'inspectionApprovedAt': FieldValue.delete(),
        'inspectionApprovedBy': FieldValue.delete(),
        'inspectionApprovedByName': FieldValue.delete(),
        'cleaningCompletedAt': FieldValue.delete(),
      });

      debugPrint('✅ [ROOM_SERVICE] Room rejected, sent back for cleaning');
      _debugLog.addLog('ROOM_SERVICE', 'Room rejected successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] rejectRoom ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error rejecting room: $e', isError: true);
      rethrow;
    }
  }

  /// Mark room as occupied (Front Office only)
  /// READY → OCCUPIED
  Future<void> markOccupied({
    required String roomId,
    required UserModel user,
  }) async {
    debugPrint('📝 [ROOM_SERVICE] markOccupied($roomId) called by ${user.displayName}');
    _debugLog.addLog('ROOM_SERVICE', 'Marking room as occupied', data: {
      'roomId': roomId,
      'userId': user.uid,
    });

    try {
      await _roomsCollection.doc(roomId).update({
        'status': RoomStatus.occupied.toFirestore(),
        'lastUpdated': Timestamp.now(),
      });

      debugPrint('✅ [ROOM_SERVICE] Room marked as occupied');
      _debugLog.addLog('ROOM_SERVICE', 'Room marked as occupied successfully');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] markOccupied ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error marking occupied: $e', isError: true);
      rethrow;
    }
  }

  // ─── INITIALIZATION ────────────────────────────────────────────────────────

  /// Initialize all rooms in the database (run once)
  /// Creates rooms for floors 2-10, 40 rooms each (201-240, 301-340, etc.)
  Future<void> initializeRooms() async {
    debugPrint('📝 [ROOM_SERVICE] initializeRooms() called');
    _debugLog.addLog('ROOM_SERVICE', 'Initializing all rooms');

    try {
      final batch = _firestore.batch();
      final now = Timestamp.now();

      // Floors 2-10, 40 rooms each
      for (int floor = 2; floor <= 10; floor++) {
        for (int roomNum = 1; roomNum <= 40; roomNum++) {
          final roomNumber = '$floor${roomNum.toString().padLeft(2, '0')}';
          final docRef = _roomsCollection.doc(roomNumber);

          batch.set(docRef, {
            'roomNumber': roomNumber,
            'floor': floor.toString(),
            'status': RoomStatus.checkout.toFirestore(),
            'lastUpdated': now,
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();
      debugPrint('✅ [ROOM_SERVICE] Rooms initialized successfully');
      _debugLog.addLog('ROOM_SERVICE', 'Rooms initialized: 360 rooms created');
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] initializeRooms ERROR: $e');
      _debugLog.addLog('ROOM_SERVICE', 'Error initializing rooms: $e', isError: true);
      rethrow;
    }
  }

  /// Check if rooms collection exists
  Future<bool> roomsExist() async {
    try {
      final snapshot = await _roomsCollection.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ─── STATISTICS ────────────────────────────────────────────────────────────

  /// Get room counts by status
  Future<Map<RoomStatus, int>> getRoomCountsByStatus() async {
    debugPrint('📝 [ROOM_SERVICE] getRoomCountsByStatus() called');

    try {
      final snapshot = await _roomsCollection.get();
      final counts = <RoomStatus, int>{};

      for (var status in RoomStatus.values) {
        counts[status] = 0;
      }

      for (var doc in snapshot.docs) {
        final statusStr = doc.data()['status'] as String? ?? 'ready';
        final status = RoomStatus.fromString(statusStr);
        counts[status] = (counts[status] ?? 0) + 1;
      }

      debugPrint('✅ [ROOM_SERVICE] Room counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] getRoomCountsByStatus ERROR: $e');
      rethrow;
    }
  }

  /// Get rooms cleaned by a specific user today
  Future<List<RoomModel>> getRoomsCleanedByUserToday(String userId) async {
    debugPrint('📝 [ROOM_SERVICE] getRoomsCleanedByUserToday($userId) called');

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _roomsCollection
          .where('cleaningStartedBy', isEqualTo: userId)
          .where('cleaningStartedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ [ROOM_SERVICE] getRoomsCleanedByUserToday ERROR: $e');
      rethrow;
    }
  }
}
