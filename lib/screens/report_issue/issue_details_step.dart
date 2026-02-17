import 'package:flutter/material.dart';

/// Step 3: Issue Details
/// User enters description and selects priority
class IssueDetailsStep extends StatefulWidget {
  final String? description;
  final String priority;
  final Function(String description, String priority) onDetailsEntered;

  const IssueDetailsStep({
    super.key,
    this.description,
    required this.priority,
    required this.onDetailsEntered,
  });

  @override
  State<IssueDetailsStep> createState() => _IssueDetailsStepState();
}

class _IssueDetailsStepState extends State<IssueDetailsStep> {
  late TextEditingController _descriptionController;
  String _selectedPriority = 'Medium';

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kYellow = Color(0xFFEAB308);
  static const Color kGreen = Color(0xFF10B981);

  // Priority options with colors
  final List<Map<String, dynamic>> _priorities = [
    {'name': 'Urgent', 'color': kRed, 'description': 'Critical - needs immediate attention'},
    {'name': 'High', 'color': kOrange, 'description': 'Important - fix within hours'},
    {'name': 'Medium', 'color': kYellow, 'description': 'Standard - fix within a day'},
    {'name': 'Low', 'color': kGreen, 'description': 'Minor - fix when convenient'},
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.description ?? '');
    _selectedPriority = widget.priority;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue => _descriptionController.text.trim().isNotEmpty;

  void _onContinue() {
    if (_canContinue) {
      widget.onDetailsEntered(_descriptionController.text.trim(), _selectedPriority);
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
            'STEP 3 OF 4',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe the issue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide details about the problem and select its priority level.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          // Description field
          const Text(
            'ISSUE DESCRIPTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What\'s the problem? Be specific...\n\nExample: "The AC unit in the room is making a loud rattling noise and not cooling properly."',
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                counterStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              style: const TextStyle(
                color: kDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Priority selection
          const Text(
            'PRIORITY LEVEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          ..._priorities.map((priority) => _buildPriorityCard(priority)),

          const SizedBox(height: 32),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinue ? _onContinue : null,
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

  Widget _buildPriorityCard(Map<String, dynamic> priority) {
    final isSelected = _selectedPriority == priority['name'];
    final color = priority['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priority['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : kDark,
                    ),
                  ),
                  Text(
                    priority['description'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? color.withOpacity(0.7) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
