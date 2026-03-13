import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking API usage and estimated costs
/// Tracks WhatsApp messages, Firebase operations, and other billable services
class UsageMetricsService {
  static final UsageMetricsService _instance = UsageMetricsService._internal();
  factory UsageMetricsService() => _instance;
  UsageMetricsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pricing constants (in USD)
  // Whapi.cloud sandbox is free, but production pricing:
  // https://whapi.cloud/pricing - approximately $0.008 per message
  static const double _whatsAppMessageCost = 0.008; // USD per message
  
  // Firebase pricing estimates (generous estimates for tracking)
  static const double _firestoreReadCost = 0.0000006; // $0.06 per 100K reads
  static const double _firestoreWriteCost = 0.000018; // $0.18 per 100K writes
  static const double _firestoreDeleteCost = 0.000002; // $0.02 per 100K deletes
  static const double _fcmNotificationCost = 0.0; // FCM is free

  /// Record a WhatsApp message being sent
  Future<void> recordWhatsAppMessage({
    required String department,
    required String messageType,
  }) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      await _firestore.collection('usage_metrics').doc(monthKey).set({
        'whatsapp_messages': FieldValue.increment(1),
        'whatsapp_cost': FieldValue.increment(_whatsAppMessageCost),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Also log individual message for detailed tracking
      await _firestore.collection('usage_metrics').doc(monthKey)
          .collection('whatsapp_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'department': department,
        'message_type': messageType,
        'cost': _whatsAppMessageCost,
      });
      
      debugPrint('📊 [METRICS] WhatsApp message recorded for $department');
    } catch (e) {
      debugPrint('❌ [METRICS] Error recording WhatsApp message: $e');
    }
  }

  /// Record Firebase Firestore operations
  Future<void> recordFirestoreOperation({
    required String operation, // 'read', 'write', 'delete'
    int count = 1,
  }) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      double cost;
      String field;
      
      switch (operation) {
        case 'read':
          cost = _firestoreReadCost * count;
          field = 'firestore_reads';
          break;
        case 'write':
          cost = _firestoreWriteCost * count;
          field = 'firestore_writes';
          break;
        case 'delete':
          cost = _firestoreDeleteCost * count;
          field = 'firestore_deletes';
          break;
        default:
          return;
      }
      
      await _firestore.collection('usage_metrics').doc(monthKey).set({
        field: FieldValue.increment(count),
        'firestore_cost': FieldValue.increment(cost),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ [METRICS] Error recording Firestore operation: $e');
    }
  }

  /// Record FCM notification sent
  Future<void> recordFCMNotification({
    required String department,
    int recipientCount = 1,
  }) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      await _firestore.collection('usage_metrics').doc(monthKey).set({
        'fcm_notifications': FieldValue.increment(recipientCount),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ [METRICS] Error recording FCM notification: $e');
    }
  }

  /// Get usage metrics for current month
  Stream<UsageMetrics> getCurrentMonthMetrics() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    return _firestore.collection('usage_metrics').doc(monthKey)
        .snapshots()
        .map((doc) => UsageMetrics.fromFirestore(doc, monthKey));
  }

  /// Get usage metrics for a specific month
  Future<UsageMetrics> getMonthMetrics(int year, int month) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    final doc = await _firestore.collection('usage_metrics').doc(monthKey).get();
    return UsageMetrics.fromFirestore(doc, monthKey);
  }

  /// Get usage metrics for the last N months
  Future<List<UsageMetrics>> getRecentMonthsMetrics(int months) async {
    final List<UsageMetrics> results = [];
    final now = DateTime.now();
    
    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final metrics = await getMonthMetrics(date.year, date.month);
      results.add(metrics);
    }
    
    return results;
  }

  /// Get WhatsApp message logs for current month
  Stream<List<WhatsAppLogEntry>> getCurrentMonthWhatsAppLogs() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    return _firestore.collection('usage_metrics').doc(monthKey)
        .collection('whatsapp_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WhatsAppLogEntry.fromFirestore(doc))
            .toList());
  }
}

/// Model for usage metrics
class UsageMetrics {
  final String monthKey;
  final int whatsAppMessages;
  final double whatsAppCost;
  final int firestoreReads;
  final int firestoreWrites;
  final int firestoreDeletes;
  final double firestoreCost;
  final int fcmNotifications;
  final DateTime? lastUpdated;

  UsageMetrics({
    required this.monthKey,
    this.whatsAppMessages = 0,
    this.whatsAppCost = 0.0,
    this.firestoreReads = 0,
    this.firestoreWrites = 0,
    this.firestoreDeletes = 0,
    this.firestoreCost = 0.0,
    this.fcmNotifications = 0,
    this.lastUpdated,
  });

  factory UsageMetrics.fromFirestore(DocumentSnapshot doc, String monthKey) {
    if (!doc.exists) {
      return UsageMetrics(monthKey: monthKey);
    }
    
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UsageMetrics(
      monthKey: monthKey,
      whatsAppMessages: (data['whatsapp_messages'] ?? 0).toInt(),
      whatsAppCost: (data['whatsapp_cost'] ?? 0.0).toDouble(),
      firestoreReads: (data['firestore_reads'] ?? 0).toInt(),
      firestoreWrites: (data['firestore_writes'] ?? 0).toInt(),
      firestoreDeletes: (data['firestore_deletes'] ?? 0).toInt(),
      firestoreCost: (data['firestore_cost'] ?? 0.0).toDouble(),
      fcmNotifications: (data['fcm_notifications'] ?? 0).toInt(),
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate(),
    );
  }

  /// Total estimated cost for the month
  double get totalCost => whatsAppCost + firestoreCost;

  /// Get month display name
  String get monthDisplayName {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${months[month - 1]} $year';
  }
}

/// Model for WhatsApp log entry
class WhatsAppLogEntry {
  final String id;
  final DateTime? timestamp;
  final String department;
  final String messageType;
  final double cost;

  WhatsAppLogEntry({
    required this.id,
    this.timestamp,
    required this.department,
    required this.messageType,
    required this.cost,
  });

  factory WhatsAppLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return WhatsAppLogEntry(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      department: data['department'] ?? 'Unknown',
      messageType: data['message_type'] ?? 'notification',
      cost: (data['cost'] ?? 0.0).toDouble(),
    );
  }
}
