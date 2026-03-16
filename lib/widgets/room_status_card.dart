import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room_model.dart';

/// Compact room status card for building view grid
/// If room has an issue, display as red regardless of cleaning status
class RoomStatusCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final bool showCleanerName;
  final bool hasIssue;

  const RoomStatusCard({
    super.key,
    required this.room,
    this.onTap,
    this.showCleanerName = false,
    this.hasIssue = false,
  });

  @override
  Widget build(BuildContext context) {
    // If room has an issue, override color to red
    final displayColor = hasIssue ? const Color(0xFFEF4444) : room.status.color;
    final displayBgColor = hasIssue ? const Color(0xFFFEF2F2) : room.status.backgroundColor;
    final displayBorderColor = hasIssue ? const Color(0xFFFECACA) : room.status.borderColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          color: displayBgColor,
          border: Border.all(
            color: displayBorderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              room.roomNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 2),
            _buildStatusIcon(displayColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Color displayColor) {
    IconData icon;
    
    // If room has an issue, show warning icon
    if (hasIssue) {
      icon = Icons.warning;
    } else {
      switch (room.status) {
        case RoomStatus.occupied:
          icon = Icons.person;
          break;
        case RoomStatus.checkout:
          icon = Icons.cleaning_services;
          break;
        case RoomStatus.cleaning:
          icon = Icons.autorenew;
          break;
        case RoomStatus.inspection:
          icon = Icons.search;
          break;
        case RoomStatus.ready:
          icon = Icons.check_circle;
          break;
      }
    }

    return Icon(
      icon,
      size: 12,
      color: displayColor.withOpacity(0.7),
    );
  }
}

/// Detailed room card for housekeeping dashboard lists
class RoomDetailCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const RoomDetailCard({
    super.key,
    required this.room,
    this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: room.status.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: room.status.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Room number + Status badge + Time
            Row(
              children: [
                // Room number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: room.status.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: room.status.borderColor),
                  ),
                  child: Text(
                    room.roomNumber,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: room.status.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.status.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.status.displayName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Time in status
                if (room.timeInStatus.isNotEmpty)
                  Text(
                    room.timeInStatus,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
            // Info rows based on status
            _buildInfoSection(),
            // Action button if provided
            if (actionButton != null) ...[
              const SizedBox(height: 12),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    switch (room.status) {
      case RoomStatus.checkout:
        return _buildInfoRow(
          icon: Icons.logout,
          label: 'Checked out by',
          value: room.checkoutByName ?? 'Unknown',
        );
      case RoomStatus.cleaning:
        return Column(
          children: [
            _buildInfoRow(
              icon: Icons.person,
              label: 'Being cleaned by',
              value: room.cleaningStartedByName ?? 'Unknown',
            ),
            if (room.rejectionNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejected: ${room.rejectionNote}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildProgressRow(),
          ],
        );
      case RoomStatus.inspection:
        return Column(
          children: [
            _buildInfoRow(
              icon: Icons.person,
              label: 'Cleaned by',
              value: room.cleaningStartedByName ?? 'Unknown',
            ),
            _buildInfoRow(
              icon: Icons.checklist,
              label: 'Checklist',
              value: 'Complete',
              valueColor: const Color(0xFF10B981),
            ),
          ],
        );
      case RoomStatus.ready:
        if (room.inspectionApprovedByName != null) {
          return _buildInfoRow(
            icon: Icons.verified,
            label: 'Approved by',
            value: room.inspectionApprovedByName!,
          );
        }
        return const SizedBox.shrink();
      case RoomStatus.occupied:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    final completed = CleaningChecklist.getCompletedCount(room.checklist);
    final total = CleaningChecklist.items.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checklist Progress',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                '$completed/$total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status legend widget for building view
class RoomStatusLegend extends StatelessWidget {
  const RoomStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: RoomStatus.values.map((status) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status.displayName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
