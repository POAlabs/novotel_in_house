import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/room_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/cleaning_checklist.dart';

/// Room Inspection Screen
/// Allows supervisor to review cleaning and approve or reject
class RoomInspectionScreen extends StatefulWidget {
  final String roomId;

  const RoomInspectionScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomInspectionScreen> createState() => _RoomInspectionScreenState();
}

class _RoomInspectionScreenState extends State<RoomInspectionScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kYellow = Color(0xFFEAB308);
  static const Color kRed = Color(0xFFEF4444);

  // Services
  final RoomService _roomService = RoomService();
  
  // State
  bool _isApproving = false;
  bool _isRejecting = false;
  final TextEditingController _rejectionNoteController = TextEditingController();

  // Get current user
  UserModel? get _currentUser => AuthService().currentUser;

  @override
  void dispose() {
    _rejectionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Room Inspection',
          style: GoogleFonts.inter(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<RoomModel?>(
        stream: _roomService.streamRoom(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = snapshot.data;
          if (room == null) {
            return Center(
              child: Text(
                'Room not found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: kGrey,
                ),
              ),
            );
          }

          final checklist = room.checklist ?? CleaningChecklist.createEmpty();
          final canApprove = _currentUser?.canApproveRooms ?? false;

          return Column(
            children: [
              // Room info header
              _buildRoomHeader(room),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cleaned by info
                      _buildCleanedByCard(room),
                      const SizedBox(height: 20),
                      
                      // Checklist summary
                      ChecklistSummary(checklist: checklist),
                      const SizedBox(height: 24),
                      
                      // Checklist items (read-only)
                      CleaningChecklistWidget(
                        checklist: checklist,
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              if (canApprove && room.status == RoomStatus.inspection)
                _buildBottomActions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomHeader(RoomModel room) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Room number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kYellow.withOpacity(0.4)),
            ),
            child: Text(
              room.roomNumber,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kYellow.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Floor ${room.floor}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Awaiting Inspection',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'INSPECTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanedByCard(RoomModel room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleaned By',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: kGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.cleaningStartedByName ?? 'Unknown Staff',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kDark,
                      ),
                    ),
                    if (room.cleaningCompletedAt != null)
                      Text(
                        'Completed ${_formatTime(room.cleaningCompletedAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kGrey,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: kGreen,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reject button
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _isApproving || _isRejecting
                      ? null
                      : _showRejectDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRed,
                    side: const BorderSide(color: kRed, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRejecting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: kRed,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'REJECT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Approve button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isApproving || _isRejecting
                      ? null
                      : _approveRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isApproving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'APPROVE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    _rejectionNoteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Room',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionNoteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.inter(color: kGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kRed, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: kGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRoom();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRoom() async {
    setState(() => _isApproving = true);

    try {
      final user = _currentUser;
      if (user == null) throw Exception('User not logged in');

      await _roomService.approveRoom(
        roomId: widget.roomId,
        user: user,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Room approved - Ready for guests',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _rejectRoom() async {
    setState(() => _isRejecting = true);

    try {
      final user = _currentUser;
      if (user == null) throw Exception('User not logged in');

      final note = _rejectionNoteController.text.trim();
      if (note.isEmpty) {
        throw Exception('Please provide a rejection reason');
      }

      await _roomService.rejectRoom(
        roomId: widget.roomId,
        user: user,
        rejectionNote: note,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Room rejected - Sent back for re-cleaning',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
