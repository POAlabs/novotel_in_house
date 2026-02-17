import 'package:flutter/material.dart';
import '../../models/floor_model.dart';

/// Step 1: Select Location
/// User selects floor and area/room
class SelectLocationStep extends StatefulWidget {
  final String? selectedFloor;
  final String? selectedArea;
  final Function(String floor, String area) onLocationSelected;

  const SelectLocationStep({
    super.key,
    this.selectedFloor,
    this.selectedArea,
    required this.onLocationSelected,
  });

  @override
  State<SelectLocationStep> createState() => _SelectLocationStepState();
}

class _SelectLocationStepState extends State<SelectLocationStep> {
  String? _selectedFloor;
  String? _selectedArea;

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kGreen = Color(0xFF10B981);

  // All hotel floors
  final List<FloorModel> _floors = const [
    FloorModel(id: '11', name: '11th Floor', areas: ['TnT', 'Kitchen', 'Corridor']),
    FloorModel(id: '10', name: '10th Floor', areas: ['Kitchen', 'Executive Lounge', 'Pool Bar', 'Swimming Pool', 'Corridor']),
    FloorModel(id: '9', name: '9th Floor', areas: ['Corridor']),
    FloorModel(id: '8', name: '8th Floor', areas: ['Corridor']),
    FloorModel(id: '7', name: '7th Floor', areas: ['Corridor']),
    FloorModel(id: '6', name: '6th Floor', areas: ['Corridor']),
    FloorModel(id: '5', name: '5th Floor', areas: ['Corridor']),
    FloorModel(id: '4', name: '4th Floor', areas: ['Corridor']),
    FloorModel(id: '3', name: '3rd Floor', areas: ['Corridor']),
    FloorModel(id: '2', name: '2nd Floor', areas: ['Corridor']),
    FloorModel(id: '1', name: '1st Floor', areas: ['Meeting Rooms', 'Washrooms', 'Spa', 'Gym', 'Corridor']),
    FloorModel(id: 'G', name: 'Ground Floor', areas: ["Gemma's", 'Main Kitchen', 'Social Hub', 'Front Office', 'Simba Ballroom', 'Corridor']),
    FloorModel(id: 'B1', name: 'Basement 1', areas: ['Back Office', 'Finance', 'Staff Cafeteria', 'Parking', 'Corridor']),
    FloorModel(id: 'B2', name: 'Basement 2', areas: ['Parking', 'Bakery', 'Control Room', 'Laundry', 'Corridor']),
    FloorModel(id: 'B3', name: 'Basement 3', areas: ['Engineering Workshop', 'Stores', 'Parking', 'Corridor']),
  ];

  @override
  void initState() {
    super.initState();
    _selectedFloor = widget.selectedFloor;
    _selectedArea = widget.selectedArea;
  }

  /// Check if floor has guest rooms (floors 2-10)
  bool _floorHasRooms(String floorId) {
    final num = int.tryParse(floorId);
    return num != null && num >= 2 && num <= 10;
  }

  /// Get current floor model
  FloorModel? get _currentFloor {
    if (_selectedFloor == null) return null;
    return _floors.firstWhere(
      (f) => f.id == _selectedFloor,
      orElse: () => _floors.first,
    );
  }

  /// Get areas for selected floor (including rooms if applicable)
  List<String> get _availableAreas {
    if (_currentFloor == null) return [];
    final areas = List<String>.from(_currentFloor!.areas);
    
    // Add room numbers for floors 2-10
    if (_floorHasRooms(_selectedFloor!)) {
      final floorNum = int.parse(_selectedFloor!);
      for (int i = 1; i <= 40; i++) {
        final roomNum = '$floorNum${i.toString().padLeft(2, '0')}';
        areas.add('Room $roomNum');
      }
    }
    
    return areas;
  }

  void _onContinue() {
    if (_selectedFloor != null && _selectedArea != null) {
      widget.onLocationSelected(_selectedFloor!, _selectedArea!);
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
            'STEP 1 OF 4',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Where is the issue?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the floor and specific area where the issue is located.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          
          // Floor selection
          const Text(
            'SELECT FLOOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          _buildFloorGrid(),
          
          // Area selection (only show if floor is selected)
          if (_selectedFloor != null) ...[
            const SizedBox(height: 32),
            const Text(
              'SELECT AREA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            _buildAreaGrid(),
          ],
          
          const SizedBox(height: 32),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedFloor != null && _selectedArea != null)
                  ? _onContinue
                  : null,
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

  Widget _buildFloorGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _floors.map((floor) {
        final isSelected = _selectedFloor == floor.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFloor = floor.id;
              _selectedArea = null; // Reset area when floor changes
            });
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? kDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kDark : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  floor.id,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  floor.name.replaceAll(' Floor', ''),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAreaGrid() {
    final areas = _availableAreas;
    final namedAreas = areas.where((a) => !a.startsWith('Room ')).toList();
    final rooms = areas.where((a) => a.startsWith('Room ')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Named areas
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: namedAreas.map((area) => _buildAreaChip(area)).toList(),
        ),
        
        // Rooms section (if any)
        if (rooms.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'GUEST ROOMS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: GridView.builder(
              scrollDirection: Axis.vertical,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) => _buildRoomChip(rooms[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAreaChip(String area) {
    final isSelected = _selectedArea == area;
    return GestureDetector(
      onTap: () => setState(() => _selectedArea = area),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kRed : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kRed : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          area,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : kDark,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomChip(String room) {
    final isSelected = _selectedArea == room;
    final roomNumber = room.replaceAll('Room ', '');
    
    return GestureDetector(
      onTap: () => setState(() => _selectedArea = room),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? kRed : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kRed : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            roomNumber,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : kDark,
            ),
          ),
        ),
      ),
    );
  }
}
