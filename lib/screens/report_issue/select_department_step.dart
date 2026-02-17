import 'package:flutter/material.dart';
import '../../config/departments.dart';

/// Step 2: Select Department
/// User selects which department should handle the issue
class SelectDepartmentStep extends StatefulWidget {
  final String? selectedDepartment;
  final Function(String department) onDepartmentSelected;

  const SelectDepartmentStep({
    super.key,
    this.selectedDepartment,
    required this.onDepartmentSelected,
  });

  @override
  State<SelectDepartmentStep> createState() => _SelectDepartmentStepState();
}

class _SelectDepartmentStepState extends State<SelectDepartmentStep> {
  String? _selectedDepartment;

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kRed = Color(0xFFEF4444);

  // Department icons
  final Map<String, IconData> _departmentIcons = {
    'Engineering': Icons.engineering,
    'IT': Icons.computer,
    'Housekeeping': Icons.cleaning_services,
    'Front Office': Icons.desk,
    'Security': Icons.security,
    'F&B': Icons.restaurant,
  };

  // Department descriptions
  final Map<String, String> _departmentDescriptions = {
    'Engineering': 'HVAC, plumbing, electrical, equipment repairs',
    'IT': 'Network, computers, software, telephones',
    'Housekeeping': 'Room cleaning, linens, supplies',
    'Front Office': 'Guest services, check-in/out, reservations',
    'Security': 'Safety, access control, emergencies',
    'F&B': 'Food & Beverage, kitchen, restaurant',
  };

  @override
  void initState() {
    super.initState();
    _selectedDepartment = widget.selectedDepartment;
  }

  void _onContinue() {
    if (_selectedDepartment != null) {
      widget.onDepartmentSelected(_selectedDepartment!);
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
            'STEP 2 OF 4',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Who should fix it?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the department responsible for handling this issue.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          // Department list
          ...Departments.all.map((dept) => _buildDepartmentCard(dept)),

          const SizedBox(height: 32),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDepartment != null ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(String department) {
    final isSelected = _selectedDepartment == department;
    final icon = _departmentIcons[department] ?? Icons.work;
    final description = _departmentDescriptions[department] ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedDepartment = department),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kRed.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kRed : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? kRed : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? kRed : kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? kRed.withOpacity(0.7) : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: kRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
