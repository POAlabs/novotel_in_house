import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import 'select_location_step.dart';
import 'select_department_step.dart';
import 'issue_details_step.dart';
import 'confirm_report_step.dart';

/// Report Issue Flow
/// Multi-step form for reporting issues
class ReportIssueFlow extends StatefulWidget {
  final String? preselectedFloor;
  final String? preselectedArea;

  const ReportIssueFlow({
    super.key,
    this.preselectedFloor,
    this.preselectedArea,
  });

  @override
  State<ReportIssueFlow> createState() => _ReportIssueFlowState();
}

class _ReportIssueFlowState extends State<ReportIssueFlow> {
  final PageController _pageController = PageController();
  final IssueService _issueService = IssueService();
  
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  String? _selectedFloor;
  String? _selectedArea;
  String? _selectedDepartment;
  String? _description;
  String _priority = 'Medium';

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    // Pre-populate if provided
    _selectedFloor = widget.preselectedFloor;
    _selectedArea = widget.preselectedArea;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  UserModel? get _currentUser => AuthService().currentUser;

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitReport() async {
    if (_currentUser == null) {
      _showError('You must be logged in to report an issue.');
      return;
    }

    if (_selectedFloor == null || _selectedArea == null || 
        _selectedDepartment == null || _description == null || _description!.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _issueService.createIssue(
        floor: _selectedFloor!,
        area: _selectedArea!,
        description: _description!,
        department: _selectedDepartment!,
        priority: _priority,
        reporter: _currentUser!,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to submit report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: _previousStep,
        ),
        title: Text(
          'Report Issue',
          style: const TextStyle(
            color: kDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _buildProgressIndicator(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Step 1: Select Location
          SelectLocationStep(
            selectedFloor: _selectedFloor,
            selectedArea: _selectedArea,
            onLocationSelected: (floor, area) {
              setState(() {
                _selectedFloor = floor;
                _selectedArea = area;
              });
              _nextStep();
            },
          ),
          // Step 2: Select Department
          SelectDepartmentStep(
            selectedDepartment: _selectedDepartment,
            onDepartmentSelected: (department) {
              setState(() => _selectedDepartment = department);
              _nextStep();
            },
          ),
          // Step 3: Issue Details
          IssueDetailsStep(
            description: _description,
            priority: _priority,
            onDetailsEntered: (description, priority) {
              setState(() {
                _description = description;
                _priority = priority;
              });
              _nextStep();
            },
          ),
          // Step 4: Confirm & Submit
          ConfirmReportStep(
            floor: _selectedFloor ?? '',
            area: _selectedArea ?? '',
            department: _selectedDepartment ?? '',
            description: _description ?? '',
            priority: _priority,
            isSubmitting: _isSubmitting,
            onSubmit: _submitReport,
            onEdit: (step) {
              _pageController.animateToPage(
                step,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentStep = step);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 4,
      color: const Color(0xFFE2E8F0),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              color: index <= _currentStep ? kRed : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }
}
