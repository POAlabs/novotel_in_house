import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/debug_log_service.dart';

/// Debug Logs Screen
/// IT admins can view, filter, and copy debug logs
class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kOrange = Color(0xFFF59E0B);

  final _debugLogService = DebugLogService();
  bool _showErrorsOnly = false;
  String? _selectedCategory;

  List<DebugLogEntry> get _filteredLogs {
    var logs = _showErrorsOnly 
        ? _debugLogService.getErrorLogs() 
        : _debugLogService.getAllLogs();
    
    if (_selectedCategory != null) {
      logs = logs.where((log) => log.category == _selectedCategory).toList();
    }
    
    return logs.reversed.toList(); // Most recent first
  }

  Set<String> get _categories {
    return _debugLogService.getAllLogs()
        .map((log) => log.category)
        .toSet();
  }

  void _copyAllLogs() {
    final logsText = _debugLogService.getLogsAsString(errorsOnly: _showErrorsOnly);
    Clipboard.setData(ClipboardData(text: logsText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logs copied to clipboard',
          style: GoogleFonts.sora(),
        ),
        backgroundColor: kGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copySelectedLog(DebugLogEntry log) {
    Clipboard.setData(ClipboardData(text: log.toFormattedString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Log entry copied',
          style: GoogleFonts.sora(),
        ),
        backgroundColor: kGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Logs', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to clear all debug logs? This cannot be undone.',
          style: GoogleFonts.sora(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.sora()),
          ),
          TextButton(
            onPressed: () {
              _debugLogService.clearLogs();
              setState(() {});
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text('Clear', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    final totalLogs = _debugLogService.logCount;
    final errorCount = _debugLogService.errorCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Debug Logs',
          style: GoogleFonts.sora(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          // Copy all logs
          IconButton(
            icon: const Icon(Icons.copy_all, color: kAccent, size: 20),
            onPressed: logs.isEmpty ? null : _copyAllLogs,
            tooltip: 'Copy All Logs',
          ),
          // Clear logs
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed, size: 20),
            onPressed: totalLogs == 0 ? null : _clearLogs,
            tooltip: 'Clear Logs',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats and filters
          _buildStatsAndFilters(totalLogs, errorCount),
          // Logs list
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState()
                : _buildLogsList(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndFilters(int totalLogs, int errorCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Stats
          Row(
            children: [
              _buildStatChip('Total', totalLogs, kAccent),
              const SizedBox(width: 8),
              _buildStatChip('Errors', errorCount, kRed),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Errors only toggle
                _buildFilterChip(
                  label: 'Errors Only',
                  isActive: _showErrorsOnly,
                  icon: Icons.error_outline,
                  onTap: () => setState(() => _showErrorsOnly = !_showErrorsOnly),
                ),
                const SizedBox(width: 8),
                // Category filters
                ..._categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: category,
                    isActive: _selectedCategory == category,
                    icon: Icons.filter_alt_outlined,
                    onTap: () => setState(() {
                      _selectedCategory = _selectedCategory == category ? null : category;
                    }),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kAccent.withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? kAccent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? kAccent : kGrey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? kAccent : kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: kGreen.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No logs available',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Logs will appear here when operations are performed',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: kGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<DebugLogEntry> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(DebugLogEntry log) {
    final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: log.isError ? kRed.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.isError ? kRed.withOpacity(0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: category, time, copy button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: log.isError ? kRed.withOpacity(0.1) : kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.category,
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: log.isError ? kRed : kAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                log.isError ? Icons.error_outline : Icons.info_outline,
                size: 16,
                color: log.isError ? kRed : kAccent,
              ),
              const Spacer(),
              Text(
                timeStr,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: kGrey.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copySelectedLog(log),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: kGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            log.message,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kDark,
            ),
          ),
          // Data (if available)
          if (log.data != null && log.data!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: log.data!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kGrey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: kDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
