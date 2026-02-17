# Issue Reporting Feature Implementation
## Overview
Implement a multi-step issue reporting flow when user presses the + button. Issues will be stored in Firebase Firestore. No image support for now (requires paid Firebase plan).
## Current State
* Employee dashboard exists with a + button in floor view (`employee_dashboard.dart:709-727`)
* `IssueModel` exists with basic fields but needs enhancement for Firebase
* No `IssueService` exists for Firestore operations
* Departments and floors are defined in config
## Proposed Changes
### 1. Update IssueModel for Firebase
* Add `reportedBy` (user ID)
* Add `reportedByName` (display name)
* Add `reportedByDepartment`
* Add `createdAt` timestamp
* Add `resolvedAt` (nullable)
* Add `resolvedBy` (nullable)
* Add `resolutionNotes` (nullable)
* Add Firestore serialization methods
### 2. Create IssueService
New file: `lib/services/issue_service.dart`
* `createIssue()` - Add issue to Firestore
* `getIssuesByDepartment()` - Stream of issues for a department
* `getAllIssues()` - Stream for admins
* `markAsResolved()` - Update issue status
### 3. Create Report Issue Screens
New folder: `lib/screens/report_issue/`
* `report_issue_flow.dart` - Main flow controller (PageView)
* `select_location_screen.dart` - Step 1: Select floor and area/room
* `select_department_screen.dart` - Step 2: Select target department
* `issue_details_screen.dart` - Step 3: Enter description and priority
* `confirm_report_screen.dart` - Step 4: Review and submit
### 4. Update Employee Dashboard
* Wire up the + button to launch report flow
* Replace mock issues with Firebase stream
### 5. Firestore Structure
Collection: `issues`
```warp-runnable-command
{
  id: auto-generated
  floor: "7"
  area: "Room 712" or "Kitchen"
  description: "AC not cooling"
  department: "Engineering"
  priority: "High" | "Medium" | "Low" | "Urgent"
  status: "Ongoing" | "Completed"
  reportedBy: "user-uid"
  reportedByName: "John Doe"
  reportedByDepartment: "Front Office"
  createdAt: Timestamp
  resolvedAt: Timestamp | null
  resolvedBy: "user-uid" | null
  resolutionNotes: string | null
}
```
