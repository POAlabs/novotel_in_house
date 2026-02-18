import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../services/issue_service.dart';
import '../config/departments.dart';

// Design colors
const Color _kDark = Color(0xFF0F172A);
const Color _kGrey = Color(0xFF64748B);
const Color _kAccent = Color(0xFF3B82F6);
const Color _kGreen = Color(0xFF10B981);
const Color _kRed = Color(0xFFEF4444);
const Color _kOrange = Color(0xFFF59E0B);

/// Shows the main Take Action bottom sheet with options
Future<void> showTakeActionSheet({
  required BuildContext context,
  required IssueModel issue,
  required UserModel currentUser,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TakeActionSheet(
      issue: issue,
      currentUser: currentUser,
    ),
  );
}

/// Main action selection sheet
class _TakeActionSheet extends StatelessWidget {
  final IssueModel issue;
  final UserModel currentUser;

  const _TakeActionSheet({
    required this.issue,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'TAKE ACTION',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.description,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${issue.floor} • ${issue.area}',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 24),
              
              // Action options
              _buildActionOption(
                context: context,
                icon: Icons.check_circle_outline,
                title: 'Mark as Resolved',
                subtitle: 'Complete this issue with resolution notes',
                color: _kGreen,
                onTap: () {
                  Navigator.pop(context);
                  _showResolveSheet(context);
                },
              ),
              const SizedBox(height: 12),
              _buildActionOption(
                context: context,
                icon: Icons.swap_horiz,
                title: 'Reassign',
                subtitle: 'Transfer to another department',
                color: _kOrange,
                onTap: () {
                  Navigator.pop(context);
                  _showReassignSheet(context);
                },
              ),
              const SizedBox(height: 12),
              _buildActionOption(
                context: context,
                icon: Icons.comment_outlined,
                title: 'Add Update',
                subtitle: 'Post a progress comment',
                color: _kAccent,
                onTap: () {
                  Navigator.pop(context);
                  _showAddCommentSheet(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: _kGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  void _showResolveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResolveIssueSheet(
        issue: issue,
        currentUser: currentUser,
      ),
    );
  }

  void _showReassignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReassignIssueSheet(
        issue: issue,
        currentUser: currentUser,
      ),
    );
  }

  void _showAddCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCommentSheet(
        issue: issue,
        currentUser: currentUser,
      ),
    );
  }
}

/// Resolve Issue Sheet
class _ResolveIssueSheet extends StatefulWidget {
  final IssueModel issue;
  final UserModel currentUser;

  const _ResolveIssueSheet({
    required this.issue,
    required this.currentUser,
  });

  @override
  State<_ResolveIssueSheet> createState() => _ResolveIssueSheetState();
}

class _ResolveIssueSheetState extends State<_ResolveIssueSheet> {
  final _notesController = TextEditingController();
  final _issueService = IssueService();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveIssue() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter resolution notes', style: GoogleFonts.sora()),
          backgroundColor: _kRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _issueService.markAsResolved(
        issueId: widget.issue.id,
        resolver: widget.currentUser,
        resolutionNotes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue marked as resolved', style: GoogleFonts.sora()),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.sora()),
            backgroundColor: _kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: _kGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mark as Resolved',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Resolution notes field
              Text(
                'RESOLUTION NOTES',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What was done to fix this issue?',
                  hintStyle: GoogleFonts.sora(color: _kGrey.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kGreen, width: 2),
                  ),
                ),
                style: GoogleFonts.sora(fontSize: 14, color: _kDark),
              ),
              const SizedBox(height: 24),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resolveIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'CONFIRM RESOLVED',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reassign Issue Sheet
class _ReassignIssueSheet extends StatefulWidget {
  final IssueModel issue;
  final UserModel currentUser;

  const _ReassignIssueSheet({
    required this.issue,
    required this.currentUser,
  });

  @override
  State<_ReassignIssueSheet> createState() => _ReassignIssueSheetState();
}

class _ReassignIssueSheetState extends State<_ReassignIssueSheet> {
  final _noteController = TextEditingController();
  final _issueService = IssueService();
  String? _selectedDepartment;
  String? _selectedPriority;
  bool _isLoading = false;

  static const List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _selectedDepartment = widget.issue.department;
    _selectedPriority = widget.issue.priority;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _reassignIssue() async {
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a department', style: GoogleFonts.sora()),
          backgroundColor: _kRed,
        ),
      );
      return;
    }

    if (_selectedDepartment == widget.issue.department && 
        _selectedPriority == widget.issue.priority) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No changes made', style: GoogleFonts.sora()),
          backgroundColor: _kOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _issueService.reassignDepartment(
        issueId: widget.issue.id,
        newDepartment: _selectedDepartment!,
        newPriority: _selectedPriority != widget.issue.priority ? _selectedPriority : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        reassignedBy: widget.currentUser,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue reassigned to $_selectedDepartment', style: GoogleFonts.sora()),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.sora()),
            backgroundColor: _kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz, color: _kOrange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reassign Issue',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Department dropdown
              Text(
                'DEPARTMENT',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: _kGrey),
                    style: GoogleFonts.sora(fontSize: 14, color: _kDark),
                    items: Departments.all.map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedDepartment = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Priority dropdown
              Text(
                'PRIORITY (OPTIONAL)',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: _kGrey),
                    style: GoogleFonts.sora(fontSize: 14, color: _kDark),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(priority),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPriority = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Note field
              Text(
                'NOTE (OPTIONAL)',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Why are you reassigning this issue?',
                  hintStyle: GoogleFonts.sora(color: _kGrey.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kOrange, width: 2),
                  ),
                ),
                style: GoogleFonts.sora(fontSize: 14, color: _kDark),
              ),
              const SizedBox(height: 24),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _reassignIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'REASSIGN ISSUE',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return _kRed;
      case 'High':
        return _kOrange;
      case 'Medium':
        return _kAccent;
      case 'Low':
        return _kGreen;
      default:
        return _kGrey;
    }
  }
}

/// Add Comment Sheet
class _AddCommentSheet extends StatefulWidget {
  final IssueModel issue;
  final UserModel currentUser;

  const _AddCommentSheet({
    required this.issue,
    required this.currentUser,
  });

  @override
  State<_AddCommentSheet> createState() => _AddCommentSheetState();
}

class _AddCommentSheetState extends State<_AddCommentSheet> {
  final _commentController = TextEditingController();
  final _issueService = IssueService();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a comment', style: GoogleFonts.sora()),
          backgroundColor: _kRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _issueService.addComment(
        issueId: widget.issue.id,
        comment: _commentController.text.trim(),
        author: widget.currentUser,
        type: 'comment',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update posted', style: GoogleFonts.sora()),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}', style: GoogleFonts.sora()),
            backgroundColor: _kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.comment_outlined, color: _kAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Update',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Comment field
              Text(
                'PROGRESS UPDATE',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What\'s the current status? (e.g., "Parts ordered, waiting for delivery")',
                  hintStyle: GoogleFonts.sora(color: _kGrey.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAccent, width: 2),
                  ),
                ),
                style: GoogleFonts.sora(fontSize: 14, color: _kDark),
              ),
              const SizedBox(height: 24),
              
              // Post button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'POST UPDATE',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
