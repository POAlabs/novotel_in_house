import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/room_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/cleaning_checklist.dart';

/// Room Cleaning Screen
/// Shows the room cleaning checklist and allows staff to mark items complete
class RoomCleaningScreen extends StatefulWidget {
  final String roomId;

  const RoomCleaningScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomCleaningScreen> createState() => _RoomCleaningScreenState();
}

class _RoomCleaningScreenState extends State<RoomCleaningScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kOrange = Color(0xFFF59E0B);

  // Services
  final RoomService _roomService = RoomService();
  
  // Loading state
  bool _isSubmitting = false;

  // Get current user
  UserModel? get _currentUser => AuthService().currentUser;

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
          'Room Cleaning',
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

          // Any housekeeping staff (or admin) can edit any room's checklist
          final canEdit = _currentUser?.isHousekeeping == true ||
              _currentUser?.isSystemAdmin == true;
          final checklist = room.checklist ?? CleaningChecklist.createEmpty();
          final isComplete = CleaningChecklist.isComplete(checklist);

          return Column(
            children: [
              // Room info header
              _buildRoomHeader(room),
              
              // Checklist
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rejection warning if any
                      if (room.rejectionNote != null) ...[
                        _buildRejectionWarning(room.rejectionNote!),
                        const SizedBox(height: 20),
                      ],
                      
                      // Checklist summary
                      ChecklistSummary(checklist: checklist),
                      const SizedBox(height: 24),
                      
                      // Checklist items
                      CleaningChecklistWidget(
                        checklist: checklist,
                        readOnly: !canEdit,
                        onItemChanged: canEdit
                            ? (key, value) => _updateChecklistItem(key, value)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action button
              if (canEdit)
                _buildBottomAction(isComplete),
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
              color: kOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOrange.withOpacity(0.3)),
            ),
            child: Text(
              room.roomNumber,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kOrange,
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
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: kGrey),
                    const SizedBox(width: 4),
                    Text(
                      room.cleaningStartedByName ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CLEANING',
              style: const TextStyle(
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

  Widget _buildRejectionWarning(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Rejected by Supervisor',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isComplete) {
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isComplete && !_isSubmitting
                ? _submitForInspection
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
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
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle : Icons.pending,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isComplete
                            ? 'SUBMIT FOR INSPECTION'
                            : 'COMPLETE ALL ITEMS',
                        style: const TextStyle(
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
    );
  }

  Future<void> _updateChecklistItem(String key, bool value) async {
    try {
      await _roomService.updateChecklistItem(
        roomId: widget.roomId,
        itemKey: key,
        value: value,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _submitForInspection() async {
    setState(() => _isSubmitting = true);

    try {
      await _roomService.completeCleaning(roomId: widget.roomId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Room submitted for inspection',
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
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
