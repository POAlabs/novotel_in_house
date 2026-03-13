import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room_model.dart';

/// Interactive cleaning checklist widget with checkboxes grouped by category
class CleaningChecklistWidget extends StatelessWidget {
  final Map<String, bool> checklist;
  final Function(String key, bool value)? onItemChanged;
  final bool readOnly;

  const CleaningChecklistWidget({
    super.key,
    required this.checklist,
    this.onItemChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bedroom section
        _buildCategorySection(
          title: 'Bedroom',
          icon: Icons.bed_outlined,
          color: const Color(0xFF3B82F6),
          items: CleaningChecklist.getByCategory('bedroom'),
        ),
        const SizedBox(height: 20),
        // Bathroom section
        _buildCategorySection(
          title: 'Bathroom',
          icon: Icons.bathroom_outlined,
          color: const Color(0xFF8B5CF6),
          items: CleaningChecklist.getByCategory('bathroom'),
        ),
        const SizedBox(height: 20),
        // General section
        _buildCategorySection(
          title: 'General',
          icon: Icons.cleaning_services_outlined,
          color: const Color(0xFF10B981),
          items: CleaningChecklist.getByCategory('general'),
        ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<ChecklistItem> items,
  }) {
    // Count completed items in this category
    int completedCount = 0;
    for (var item in items) {
      if (checklist[item.key] == true) completedCount++;
    }
    final isComplete = completedCount == items.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? const Color(0xFF10B981) : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/${items.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Checklist items
          ...items.map((item) => _buildChecklistItem(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    final isChecked = checklist[item.key] ?? false;

    return InkWell(
      onTap: readOnly
          ? null
          : () => onItemChanged?.call(item.key, !isChecked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Row(
          children: [
            // Custom checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                  color: isChecked
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Status icon
            if (isChecked)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xFF10B981),
              ),
          ],
        ),
      ),
    );
  }
}

/// Summary widget showing checklist completion status
class ChecklistSummary extends StatelessWidget {
  final Map<String, bool>? checklist;

  const ChecklistSummary({
    super.key,
    required this.checklist,
  });

  @override
  Widget build(BuildContext context) {
    final completed = CleaningChecklist.getCompletedCount(checklist);
    final total = CleaningChecklist.items.length;
    final progress = total > 0 ? completed / total : 0.0;
    final isComplete = completed == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.pending,
                    color: isComplete
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete ? 'Checklist Complete' : 'Checklist In Progress',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isComplete
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              Text(
                '$completed/$total',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only checklist view for inspection screen
class ChecklistReadOnlyView extends StatelessWidget {
  final Map<String, bool>? checklist;

  const ChecklistReadOnlyView({
    super.key,
    required this.checklist,
  });

  @override
  Widget build(BuildContext context) {
    return CleaningChecklistWidget(
      checklist: checklist ?? CleaningChecklist.createEmpty(),
      readOnly: true,
    );
  }
}
