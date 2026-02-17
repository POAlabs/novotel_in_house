import 'package:flutter/material.dart';

/// Step 4: Confirm Report
/// User reviews all information and submits
class ConfirmReportStep extends StatelessWidget {
  final String floor;
  final String area;
  final String department;
  final String description;
  final String priority;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Function(int step) onEdit;

  const ConfirmReportStep({
    super.key,
    required this.floor,
    required this.area,
    required this.department,
    required this.description,
    required this.priority,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onEdit,
  });

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kYellow = Color(0xFFEAB308);
  static const Color kGreen = Color(0xFF10B981);

  Color get _priorityColor {
    switch (priority) {
      case 'Urgent':
        return kRed;
      case 'High':
        return kOrange;
      case 'Medium':
        return kYellow;
      case 'Low':
        return kGreen;
      default:
        return kYellow;
    }
  }

  String get _floorDisplayName {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          const Text(
            'STEP 4 OF 4',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please verify all information before submitting your report.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _priorityColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onEdit(2),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // Location row
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'LOCATION',
                  value: '$_floorDisplayName • $area',
                  onEdit: () => onEdit(0),
                ),
                const SizedBox(height: 16),

                // Department row
                _buildInfoRow(
                  icon: Icons.people,
                  label: 'ASSIGNED TO',
                  value: department,
                  onEdit: () => onEdit(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: kOrange, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'The assigned department will be notified immediately after you submit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kRed.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'SUBMIT REPORT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kDark,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
