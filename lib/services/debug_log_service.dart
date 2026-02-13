import 'package:flutter/foundation.dart';

/// Service for storing debug logs in memory
/// Allows IT admins to view logs from within the app
class DebugLogService {
  // Singleton instance
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  // Store logs in memory (max 500 entries)
  final List<DebugLogEntry> _logs = [];
  static const int _maxLogs = 500;

  /// Add a new log entry
  void addLog(
    String category,
    String message, {
    Map<String, dynamic>? data,
    bool isError = false,
  }) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      data: data,
      isError: isError,
    );

    _logs.add(entry);
    
    // Keep only last 500 logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Also print to console
    final prefix = isError ? '❌' : '📝';
    debugPrint('$prefix [$category] $message');
    if (data != null && data.isNotEmpty) {
      debugPrint('   Data: $data');
    }
  }

  /// Get all logs
  List<DebugLogEntry> getAllLogs() => List.unmodifiable(_logs);

  /// Get logs by category
  List<DebugLogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }

  /// Get error logs only
  List<DebugLogEntry> getErrorLogs() {
    return _logs.where((log) => log.isError).toList();
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
    debugPrint('🗑️ [DEBUG_LOG_SERVICE] All logs cleared');
  }

  /// Get logs as formatted string
  String getLogsAsString({bool errorsOnly = false}) {
    final logsToFormat = errorsOnly ? getErrorLogs() : _logs;
    
    if (logsToFormat.isEmpty) {
      return 'No logs available';
    }

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('DEBUG LOGS - ${DateTime.now()}');
    buffer.writeln('Total: ${logsToFormat.length} entries');
    buffer.writeln('═══════════════════════════════════════════════════════\n');

    for (final log in logsToFormat) {
      buffer.writeln(log.toFormattedString());
      buffer.writeln('───────────────────────────────────────────────────────');
    }

    return buffer.toString();
  }

  /// Get log count
  int get logCount => _logs.length;

  /// Get error count
  int get errorCount => _logs.where((log) => log.isError).length;
}

/// Single log entry
class DebugLogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final Map<String, dynamic>? data;
  final bool isError;

  DebugLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.data,
    this.isError = false,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    
    // Timestamp and category
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    
    final prefix = isError ? '❌ ERROR' : '📝 INFO';
    buffer.writeln('$prefix [$category] $timeStr');
    
    // Message
    buffer.writeln('Message: $message');
    
    // Data (if available)
    if (data != null && data!.isNotEmpty) {
      buffer.writeln('Data:');
      data!.forEach((key, value) {
        buffer.writeln('  • $key: $value');
      });
    }
    
    return buffer.toString();
  }

  String toShortString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$category] $timeStr - $message';
  }
}
