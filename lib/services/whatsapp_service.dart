import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'debug_log_service.dart';

/// Service for sending WhatsApp notifications via Whapi.cloud
class WhatsAppService {
  static const String _apiToken = 'kpiV2vkaupTy77mME0QoRW0m4FT0MPcM';
  static const String _groupId = '120363426242965978@g.us';
  
  static const String _baseUrl = 'https://gate.whapi.cloud';
  
  final DebugLogService _debugLog = DebugLogService();

  // Singleton instance
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Send issue notification to WhatsApp group
  Future<bool> sendIssueNotification({
    required String department,
    required String reportedByName,
    required String floor,
    required String area,
    required String priority,
    required String description,
  }) async {
    debugPrint('📱 [WHATSAPP_SERVICE] Sending issue notification...');
    _debugLog.addLog(
      'WHATSAPP_SERVICE',
      'Sending WhatsApp notification',
      data: {
        'department': department,
        'reportedBy': reportedByName,
        'floor': floor,
        'area': area,
        'priority': priority,
        'description': description.length > 50 
            ? '${description.substring(0, 50)}...' 
            : description,
      },
    );
    
    try {
      final message = _formatIssueMessage(
        department: department,
        reportedByName: reportedByName,
        floor: floor,
        area: area,
        priority: priority,
        description: description,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/messages/text'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': _groupId,
          'body': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [WHATSAPP_SERVICE] Message sent successfully');
        _debugLog.addLog(
          'WHATSAPP_SERVICE',
          'WhatsApp notification sent successfully',
          data: {
            'department': department,
            'reportedBy': reportedByName,
            'location': '$floor - $area',
            'priority': priority,
            'statusCode': response.statusCode,
          },
        );
        return true;
      } else {
        debugPrint('❌ [WHATSAPP_SERVICE] Failed to send message: ${response.statusCode} - ${response.body}');
        _debugLog.addLog(
          'WHATSAPP_SERVICE',
          'WhatsApp notification failed',
          data: {
            'department': department,
            'statusCode': response.statusCode,
            'error': response.body,
          },
          isError: true,
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WHATSAPP_SERVICE] Error sending message: $e');
      _debugLog.addLog(
        'WHATSAPP_SERVICE',
        'WhatsApp notification error: $e',
        data: {
          'department': department,
          'reportedBy': reportedByName,
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      return false;
    }
  }

  /// Format the issue message for WhatsApp
  String _formatIssueMessage({
    required String department,
    required String reportedByName,
    required String floor,
    required String area,
    required String priority,
    required String description,
  }) {
    final timestamp = _formatTimestamp(DateTime.now());
    final floorDisplay = _getFloorDisplayName(floor);
    final priorityEmoji = _getPriorityEmoji(priority);

    return '''
🚨 *NEW ISSUE REPORTED*

📍 *DEPARTMENT: ${department.toUpperCase()}*
👤 Reported by: $reportedByName
🏢 Location: $floorDisplay • $area
$priorityEmoji Priority: $priority
📝 Description: $description

🕐 $timestamp
''';
  }

  /// Get emoji based on priority
  String _getPriorityEmoji(String priority) {
    switch (priority) {
      case 'Urgent':
        return '🔴';
      case 'High':
        return '🟠';
      case 'Medium':
        return '🟡';
      case 'Low':
        return '🟢';
      default:
        return '⚡';
    }
  }

  /// Format floor for display
  String _getFloorDisplayName(String floor) {
    switch (floor) {
      case 'G':
        return 'Ground Floor';
      case 'B1':
        return 'Basement 1';
      case 'B2':
        return 'Basement 2';
      case 'B3':
        return 'Basement 3';
      case '1':
        return '1st Floor';
      case '2':
        return '2nd Floor';
      case '3':
        return '3rd Floor';
      default:
        final num = int.tryParse(floor);
        if (num != null) return '${num}th Floor';
        return 'Floor $floor';
    }
  }

  /// Format timestamp
  String _formatTimestamp(DateTime dateTime) {
    final day = dateTime.day;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final hourDisplay = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$day $month $year, $hourDisplay:$minute $period';
  }
}
