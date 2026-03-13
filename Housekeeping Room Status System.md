# Housekeeping Room Status System
A complete room cleaning workflow for Novotel's housekeeping operations.
## Overview
### Current State
* Rooms exist as areas in the floor model (floors 2-10, 40 rooms each: e.g., 701-740)
* No room status tracking beyond issue reporting
* No cleaning workflow or checklist system
### Proposed System
A real-time room status system with:
* 5 distinct room states with clear visual indicators
* Cleaning checklist (same for checkout and daily clean)
* Role-based actions (Front Office, Housekeeping Staff, Housekeeping Supervisor)
* Full accountability tracking
## Room Status Flow
```warp-runnable-command
OCCUPIED (Blue) → Guest in room
    ↓ [Front Office marks checkout]
CHECKOUT (Red) → Needs cleaning, visible to Housekeeping
    ↓ [Housekeeping staff starts cleaning]
CLEANING (Orange) → In progress, shows cleaner name
    ↓ [Staff completes checklist]
INSPECTION (Yellow) → Waiting supervisor approval
    ↓ [Supervisor approves]
READY (Green) → Available for booking
    ↓ [Front Office assigns guest]
OCCUPIED (Blue)
```
## Data Model
### New Firestore Collection: `rooms`
```warp-runnable-command
rooms/{roomId}
  - roomNumber: "701" (String)
  - floor: "7" (String)
  - status: "occupied" | "checkout" | "cleaning" | "inspection" | "ready"
  - guestName: "John Doe" (optional, for reference)
  - checkoutAt: Timestamp (when marked checkout)
  - checkoutBy: UID (Front Office user)
  - checkoutByName: String
  - cleaningStartedAt: Timestamp
  - cleaningStartedBy: UID (Housekeeping staff)
  - cleaningStartedByName: String
  - cleaningCompletedAt: Timestamp
  - checklist: Map<String, bool> (checklist items)
  - inspectionApprovedAt: Timestamp
  - inspectionApprovedBy: UID (Supervisor)
  - inspectionApprovedByName: String
  - readyAt: Timestamp
  - lastUpdated: Timestamp
```
### Cleaning Checklist Items (stored in checklist map)
**Bedroom:**
* `bedMade`: Bed made
* `sheetsChanged`: Sheets changed
* `dustingDone`: Dusting completed
* `floorVacuumed`: Floor vacuumed
**Bathroom:**
* `toiletCleaned`: Toilet cleaned & sanitized
* `showerCleaned`: Shower/tub cleaned
* `towelsReplaced`: Towels replaced
* `amenitiesRestocked`: Amenities restocked (soap, shampoo)
**General:**
* `trashEmptied`: Trash emptied
* `windowsCleaned`: Windows & mirrors cleaned
## Role Permissions
**New Role Added:** `supervisor` (between staff and manager)
| Action | Front Office | HK Staff | HK Supervisor | HK Manager |
|--------|--------------|----------|---------------|------------|
| Mark Checkout | ✓ | | | |
| Start Cleaning | | ✓ | ✓ | ✓ |
| Complete Checklist | | ✓ | ✓ | ✓ |
| Approve (Mark Ready) | | | ✓ | ✓ |
| Mark as Occupied | ✓ | | | |
| View All Rooms | ✓ | ✓ | ✓ | ✓ |
**Front Office:** Sees all rooms and all statuses (full visibility like managers)
## New Files to Create
### Models
1. `lib/models/room_model.dart` - Room data model with status enum
### Services
2. `lib/services/room_service.dart` - Firestore CRUD for rooms
### Screens
3. `lib/screens/housekeeping/housekeeping_dashboard.dart` - Main HK view (list of rooms needing attention)
4. `lib/screens/housekeeping/room_cleaning_screen.dart` - Checklist screen for cleaning a room
5. `lib/screens/housekeeping/room_inspection_screen.dart` - Supervisor inspection/approval screen
### Widgets
6. `lib/widgets/room_status_card.dart` - Reusable room card showing status
7. `lib/widgets/cleaning_checklist.dart` - Checklist widget with checkboxes
## UI Design
### Room Status Colors
* **OCCUPIED**: Blue (`#3B82F6`) - Guest in room
* **CHECKOUT**: Red (`#EF4444`) - Needs cleaning (URGENT)
* **CLEANING**: Orange (`#F59E0B`) - Being cleaned
* **INSPECTION**: Yellow (`#EAB308`) - Awaiting approval
* **READY**: Green (`#10B981`) - Available
### Building Tab Integration
Room cards in the building view will show:
* Room number
* Current status (color-coded)
* Cleaner name (if cleaning/inspection)
* Time in current state
### Housekeeping Dashboard
Shows filtered lists:
* "Needs Cleaning" (checkout status) - RED section
* "In Progress" (cleaning status) - ORANGE section
* "Awaiting Inspection" (inspection status) - YELLOW section, Supervisor only
### Cleaning Screen
* Room number header
* Checklist with checkboxes (grouped by Bedroom/Bathroom/General)
* "Complete Cleaning" button (disabled until all checked)
* Clear visual progress indicator
### Inspection Screen (Supervisor)
* Room number and cleaner info
* View completed checklist (read-only)
* "Approve" button → marks as READY
* "Reject" button → sends back to CLEANING with note
## Implementation Steps
1. Create `RoomModel` and `RoomStatus` enum
2. Create `RoomService` with all Firestore operations
3. Create room status card widget
4. Create cleaning checklist widget
5. Create Housekeeping dashboard screen
6. Create room cleaning screen with checklist
7. Create inspection screen for supervisors
8. Update Building tab to show room statuses
9. Add housekeeping access to bottom nav for HK department users
10. Initialize rooms collection with all 360 rooms (floors 2-10, 40 each)
