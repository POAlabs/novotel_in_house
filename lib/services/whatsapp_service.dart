import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'debug_log_service.dart';
import 'usage_metrics_service.dart';

/// Service for sending WhatsApp notifications via Whapi.cloud
class WhatsAppService {
  static const String _apiToken = '8HRmKIFBhmduyK1BegLA3VQd3BQ23W9t';
  static const String _groupId = '120363426242965978@g.us';
  
  static const String _baseUrl = 'https://gate.whapi.cloud';
  
  final DebugLogService _debugLog = DebugLogService();
  final UsageMetricsService _metricsService = UsageMetricsService();

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
    debugPrint('\n' + '='*80);
    debugPrint('📱 [WHATSAPP_SERVICE] ===== STARTING WHATSAPP NOTIFICATION =====');
    debugPrint('='*80);
    debugPrint('📱 [WHATSAPP_SERVICE] Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('📱 [WHATSAPP_SERVICE] Department: $department');
    debugPrint('📱 [WHATSAPP_SERVICE] Reported By: $reportedByName');
    debugPrint('📱 [WHATSAPP_SERVICE] Location: Floor $floor - $area');
    debugPrint('📱 [WHATSAPP_SERVICE] Priority: $priority');
    debugPrint('📱 [WHATSAPP_SERVICE] Description: $description');
    debugPrint('📱 [WHATSAPP_SERVICE] API Token (first 10 chars): ${_apiToken.substring(0, 10)}...');
    debugPrint('📱 [WHATSAPP_SERVICE] Group ID: $_groupId');
    debugPrint('📱 [WHATSAPP_SERVICE] Base URL: $_baseUrl');
    
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
        'timestamp': DateTime.now().toIso8601String(),
        'groupId': _groupId,
      },
    );
    
    try {
      debugPrint('📱 [WHATSAPP_SERVICE] Step 1: Formatting message...');
      final message = _formatIssueMessage(
        department: department,
        reportedByName: reportedByName,
        floor: floor,
        area: area,
        priority: priority,
        description: description,
      );
      debugPrint('📱 [WHATSAPP_SERVICE] Step 2: Message formatted successfully');
      debugPrint('📱 [WHATSAPP_SERVICE] Message preview:');
      debugPrint('--- MESSAGE START ---');
      debugPrint(message);
      debugPrint('--- MESSAGE END ---');

      debugPrint('📱 [WHATSAPP_SERVICE] Step 3: Preparing HTTP request...');
      final url = '$_baseUrl/messages/text';
      final requestBody = {
        'to': _groupId,
        'body': message,
      };
      final requestBodyJson = jsonEncode(requestBody);
      
      debugPrint('📱 [WHATSAPP_SERVICE] Request URL: $url');
      debugPrint('📱 [WHATSAPP_SERVICE] Request Body: $requestBodyJson');
      debugPrint('📱 [WHATSAPP_SERVICE] Step 4: Sending HTTP POST request...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: requestBodyJson,
      );
      
      debugPrint('📱 [WHATSAPP_SERVICE] Step 5: Received HTTP response');
      debugPrint('📱 [WHATSAPP_SERVICE] Response Status Code: ${response.statusCode}');
      debugPrint('📱 [WHATSAPP_SERVICE] Response Body: ${response.body}');
      debugPrint('📱 [WHATSAPP_SERVICE] Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅✅✅ [WHATSAPP_SERVICE] SUCCESS! Message sent successfully ✅✅✅');
        debugPrint('✅ [WHATSAPP_SERVICE] Status Code: ${response.statusCode}');
        debugPrint('✅ [WHATSAPP_SERVICE] Response: ${response.body}');
        
        _debugLog.addLog(
          'WHATSAPP_SERVICE',
          'WhatsApp notification sent successfully',
          data: {
            'department': department,
            'reportedBy': reportedByName,
            'location': '$floor - $area',
            'priority': priority,
            'statusCode': response.statusCode,
            'responseBody': response.body,
          },
        );
        
        // Track WhatsApp message for billing metrics
        debugPrint('📊 [WHATSAPP_SERVICE] Recording metrics...');
        await _metricsService.recordWhatsAppMessage(
          department: department,
          messageType: 'issue_notification',
        );
        debugPrint('📊 [WHATSAPP_SERVICE] Metrics recorded');
        
        debugPrint('='*80);
        debugPrint('📱 [WHATSAPP_SERVICE] ===== WHATSAPP NOTIFICATION COMPLETE =====');
        debugPrint('='*80 + '\n');
        
        return true;
      } else {
        debugPrint('❌❌❌ [WHATSAPP_SERVICE] FAILED! Message not sent ❌❌❌');
        debugPrint('❌ [WHATSAPP_SERVICE] Status Code: ${response.statusCode}');
        debugPrint('❌ [WHATSAPP_SERVICE] Response Body: ${response.body}');
        debugPrint('❌ [WHATSAPP_SERVICE] Response Headers: ${response.headers}');
        
        // Try to parse error details
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('❌ [WHATSAPP_SERVICE] Parsed Error: $errorData');
        } catch (e) {
          debugPrint('❌ [WHATSAPP_SERVICE] Could not parse error response');
        }
        
        _debugLog.addLog(
          'WHATSAPP_SERVICE',
          'WhatsApp notification failed',
          data: {
            'department': department,
            'statusCode': response.statusCode,
            'error': response.body,
            'headers': response.headers.toString(),
          },
          isError: true,
        );
        
        debugPrint('='*80);
        debugPrint('❌ [WHATSAPP_SERVICE] ===== WHATSAPP NOTIFICATION FAILED =====');
        debugPrint('='*80 + '\n');
        
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('💥💥💥 [WHATSAPP_SERVICE] EXCEPTION CAUGHT! 💥💥💥');
      debugPrint('💥 [WHATSAPP_SERVICE] Exception Type: ${e.runtimeType}');
      debugPrint('💥 [WHATSAPP_SERVICE] Exception Message: $e');
      debugPrint('💥 [WHATSAPP_SERVICE] Stack Trace:');
      debugPrint(stackTrace.toString());
      
      _debugLog.addLog(
        'WHATSAPP_SERVICE',
        'WhatsApp notification error: $e',
        data: {
          'department': department,
          'reportedBy': reportedByName,
          'exceptionType': e.runtimeType.toString(),
          'exceptionMessage': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      
      debugPrint('='*80);
      debugPrint('💥 [WHATSAPP_SERVICE] ===== WHATSAPP NOTIFICATION EXCEPTION =====');
      debugPrint('='*80 + '\n');
      
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
