import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';

/// Screen to display history of resolved issues
/// Staff see only their department issues
/// Admins and managers see all issues
class IssueHistoryScreen extends StatelessWidget {
  const IssueHistoryScreen({super.key});

  /// Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  /// Check if current user can view this issue
  bool _canViewIssue(IssueModel issue) {
    if (_currentUser == null) return false;
    // System admins and managers can see all issues
    if (_currentUser!.isSystemAdmin || _currentUser!.role.name == 'manager') {
      return true;
    }
    // Staff can only see issues for their department
    return issue.department == _currentUser!.department;
  }

  // Design colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kAccent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Inline header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Issue History',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<IssueModel>>(
        stream: IssueService().getResolvedIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: kGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: GoogleFonts.sora(color: kGrey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Filter issues based on department visibility
          final allIssues = snapshot.data ?? [];
          final issues = allIssues.where((i) => _canViewIssue(i)).toList();

          if (issues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: kGrey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No resolved issues yet',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: kGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed issues will appear here',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: kGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return _buildIssueCard(context, issue);
            },
          );
        },
      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $period';
  }

  Widget _buildIssueCard(BuildContext context, IssueModel issue) {
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: kGreen, size: 22),
          ),
          title: Text(
            issue.description,
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: kDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildChip(issue.floor, kAccent),
                const SizedBox(width: 6),
                _buildChip(issue.department, kGrey),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  _buildInfoRow(Icons.location_on_outlined, 'Location', '${issue.floor} • ${issue.area}'),
                  const SizedBox(height: 10),
                  
                  // Reported by
                  _buildInfoRow(Icons.person_outline, 'Reported by', '${issue.reportedByName} (${issue.reportedByDepartment})'),
                  const SizedBox(height: 10),
                  
                  // Reported at
                  _buildInfoRow(Icons.schedule, 'Reported', _formatDate(issue.createdAt)),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  
                  // Resolved by
                  _buildInfoRow(
                    Icons.check_circle_outline, 
                    'Resolved by', 
                    issue.resolvedByName ?? 'Unknown',
                    iconColor: kGreen,
                  ),
                  const SizedBox(height: 10),
                  
                  // Resolved at
                  if (issue.resolvedAt != null)
                    _buildInfoRow(
                      Icons.event_available, 
                      'Resolved', 
                      _formatDate(issue.resolvedAt!),
                      iconColor: kGreen,
                    ),
                  
                  // Resolution notes
                  if (issue.resolutionNotes != null && issue.resolutionNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kGreen.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resolution Notes',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issue.resolutionNotes!,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              color: kDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? kGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: kGrey,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
