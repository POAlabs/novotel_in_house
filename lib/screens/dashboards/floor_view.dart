import 'package:flutter/material.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';

/// Floor visualization screen
/// Displays area diagnostics for a specific floor
class FloorView extends StatelessWidget {
  final FloorModel floor;
  final List<IssueModel> issues;

  const FloorView({
    super.key,
    required this.floor,
    required this.issues,
  });

  /// Get issues specific to this floor
  List<IssueModel> get _floorIssues {
    return issues
        .where((issue) => issue.floor == floor.id && issue.status == 'Ongoing')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFloorTitle(),
                    const SizedBox(height: 32),
                    _buildAreaGrid(),
                    if (_floorIssues.isNotEmpty) ...[
                      const SizedBox(height: 48),
                      _buildActiveIssues(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top navigation header
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Text(
            'FLOOR ${floor.id}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// Floor title section
  Widget _buildFloorTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FLOOR ${floor.id}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            height: 0.9,
            letterSpacing: -2,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'DIAGNOSTIC MATRIX',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  /// Grid of area cards
  Widget _buildAreaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: floor.areas.length,
      itemBuilder: (context, index) {
        final area = floor.areas[index];
        final hasIssue = issues.any(
          (issue) =>
              issue.area == area &&
              issue.floor == floor.id &&
              issue.status == 'Ongoing',
        );
        return _buildAreaCard(area, hasIssue);
      },
    );
  }

  /// Individual area diagnostic card
  Widget _buildAreaCard(String area, bool hasIssue) {
    return Container(
      decoration: BoxDecoration(
        color: hasIssue
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue
              ? const Color(0xFFFECACA)
              : const Color(0xFFBBF7D0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.location_on,
                size: 24,
                color: hasIssue
                    ? const Color(0xFFEF4444).withOpacity(0.6)
                    : const Color(0xFF10B981).withOpacity(0.4),
              ),
              if (!hasIssue)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
            ],
          ),
          // Bottom section with text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: hasIssue
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasIssue ? 'BREACH DETECTED' : 'OPERATIONAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: hasIssue
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF10B981).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Active issues list for this floor
  Widget _buildActiveIssues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: const Color(0xFFE2E8F0),
          margin: const EdgeInsets.only(bottom: 32),
        ),
        ..._floorIssues.map((issue) => _buildIssueCard(issue)),
      ],
    );
  }

  /// Individual issue alert card
  Widget _buildIssueCard(IssueModel issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(
          color: const Color(0xFFFECACA),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority badge and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  issue.priority.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                issue.timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            issue.description.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Area
          Text(
            issue.area.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ACKNOWLEDGE BREACH',
                style: TextStyle(
                  fontSize: 11,
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
}
