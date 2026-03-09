# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Novotel In-House is a Flutter app for Novotel Westlands hotel operations. It is a facility issue-tracking and diagnostic system where staff report building issues (maintenance, security, etc.), managers oversee departments, and system admins have full visibility. The backend is Firebase (Auth, Firestore, Cloud Messaging). Push notification logic lives in Firebase Cloud Functions (`functions/`).

## Build & Run Commands

```
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter build apk --release  # Build release APK
flutter analyze              # Static analysis (uses flutter_lints)
flutter test                 # Run tests (test/ directory)
```

Cloud Functions (inside `functions/`):
```
npm install                          # Install function dependencies
firebase emulators:start --only functions  # Local emulation
firebase deploy --only functions     # Deploy to production
npm run lint                         # Lint functions code
```

CI builds on push to `master` via `.github/workflows/build.yml` using Flutter 3.38.9 and Java 17.

## Architecture

### Role-Based Dashboard System

The app routes users to different dashboards based on `UserRole` (defined in `lib/config/departments.dart`):

- **staff** → `EmployeeDashboard` — sees only issues for their department. Uses bottom navigation (Building / Home / Settings). Can report issues.
- **manager** → `ManagerDashboard` — sees all departments' issues. Has analytics section (`AnalyticsSection` widget with fl_chart). Bottom navigation with department drill-down.
- **systemAdmin** → `AdminDashboard` — sees everything. Uses a sidebar navigation rail (not bottom nav). Can manage users (add/edit/deactivate) and view debug logs.

Route selection happens in `_AuthGateScreen` (in `lib/config/routes.dart`) which checks for an existing Firebase session on startup and redirects accordingly.

### Demo/Fallback Mode

If Firebase fails to initialize, the app sets `AuthService.firebaseInitialized = false` and runs in demo mode. All Firebase-dependent services check this flag.

### Service Layer (Singletons)

All services use the singleton pattern (`factory` constructor returning `_instance`):

- `AuthService` — Firebase Auth sign-in/sign-out, session restore, caches `UserModel` in `_currentUser`
- `IssueService` — Firestore CRUD on `issues` collection. Returns real-time `Stream<List<IssueModel>>`. Issues have a `comments` subcollection (`issues/{id}/comments`)
- `UserService` — Admin-only user management. Creates both Firebase Auth accounts and Firestore `users` documents
- `NotificationService` — FCM token management, topic subscriptions (format: `department_<name>`, `role_<name>`, `all_users`), foreground notification display via `flutter_local_notifications`
- `AnalyticsService` — Computes analytics from Firestore queries over configurable date ranges
- `DebugLogService` — In-memory debug log, viewable by admins
- `LostItemService` — Lost & found item tracking

### Data Models

All Firestore-backed models follow the same pattern: `fromFirestore(DocumentSnapshot)`, `toFirestore()`, `copyWith(...)`, plus optional `fromJson`/`toJson` for legacy support. Key models:

- `IssueModel` — floor, area, description, status (`Ongoing`/`Completed`), priority (`Urgent`/`High`/`Medium`/`Low`), department, reporter info, resolution info
- `UserModel` — uid, email, displayName, role (`UserRole` enum), department, isActive, fcmToken
- `FloorModel` — id, name, areas list
- `IssueCommentModel` — subcollection under issues, has type field (`comment`, `reassign`, `resolved`, etc.)
- `LostItemModel` — status (`Found`/`Claimed`/`Disposed`)

### Floor/Area Structure

The hotel has 15 floors (B3 to 11). The floor list is hardcoded in each dashboard widget (not centralized). Floors 2-9 are guest room floors with `['General']` areas. Special floors (G, B1-B3, 1, 10, 11) have named areas (e.g., `"Gemma's"`, `'Main Kitchen'`, `'Simba Ballroom'`). Every floor includes a `'General'` catch-all area.

### Report Issue Flow

`ReportIssueFlow` is a 4-step `PageView` wizard: Select Location → Select Department → Issue Details (description + priority) → Confirm. Each step is a separate widget in `lib/screens/report_issue/`.

### Push Notifications (Cloud Functions)

`functions/index.js` has two Firestore triggers:
- `onIssueCreated` — notifies the target department topic; also notifies `role_system_admin` topic if priority is `Urgent`
- `onIssueUpdated` — notifies reporter via FCM token on resolution; notifies new department on reassignment; notifies admins on escalation to Urgent

### Design System

- Font: **Sora** via `google_fonts` package
- Color palette: Slate background (`#F8FAFC`), dark text (`#0F172A`), emerald green (`#10B981`) for healthy/operational, red (`#EF4444`) for issues/breaches. Priority colors: Urgent=deep red, High=orange-red, Medium=amber, Low=yellow
- High border-radius values (24-48px) for a premium feel
- Issue status is binary: `Ongoing` (red) or `Completed` (green) — no intermediate states
- The logo file is in `.jfif` format (`assets/logo.jfif`)

### Departments

Defined in `lib/config/departments.dart`: Engineering, IT, Housekeeping, Front Office, Security, F&B.

## Firestore Collections

- `users` — keyed by Firebase Auth UID
- `issues` — auto-generated IDs, with `comments` subcollection
- Lost items collection (managed by `LostItemService`)

## Key Patterns to Follow

- Services are singletons — instantiate via `ServiceName()` factory constructor
- All dashboards use `StreamBuilder` with `IssueService` streams for real-time updates
- The `_canViewIssue` method on employee dashboard filters issues by the user's department
- Back-button behavior is handled via `PopScope` with `_handleBackPress()` returning whether the press was consumed internally
- Debug logging uses `DebugLogService().addLog(tag, message, data:, isError:)` — keep this pattern when adding new service methods
