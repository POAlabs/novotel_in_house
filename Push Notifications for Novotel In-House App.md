# Push Notifications Implementation Plan
## Problem Statement

The Novotel In-House hotel operations app currently has no notification system. Staff (employees, managers, admins) need to be notified in real-time when:
* New issues are reported to their department
* Issues are reassigned to their department
* Issues they reported are resolved
* High-priority/urgent issues are created (for admins)

## Current State
* Flutter app with Firebase Auth + Cloud Firestore
* Three user roles: Staff, Manager, System Admin
* Issues are department-based (Engineering, IT, Housekeeping, etc.)
* No push notification infrastructure exists
* `pubspec.yaml` has firebase_core, firebase_auth, cloud_firestore

## Proposed Solution
Use **Firebase Cloud Messaging (FCM)** for push notifications with Firestore-triggered Cloud Functions.

### Architecture
1. **Client-side (Flutter)**
    * Add `firebase_messaging` package
    * Request notification permissions on login
    * Store FCM tokens in Firestore user documents
    * Handle foreground/background notifications
    * Navigate to relevant screen on notification tap
2. **Backend (Firebase Cloud Functions)**
    * Firestore triggers on `issues` collection changes
    * Send notifications based on event type and user roles/departments
    * Use FCM Admin SDK to send targeted notifications

## Implementation Steps
### Step 1: Flutter Dependencies

Add to `pubspec.yaml`:
* `firebase_messaging: ^15.1.6`
* `flutter_local_notifications: ^18.0.1` (for foreground display)

### Step 2: Create NotificationService
New file: `lib/services/notification_service.dart`
* Initialize FCM
* Request permissions (iOS/Android)
* Get and store FCM token
* Listen for token refresh
* Handle incoming messages

### Step 3: Update UserModel & Firestore
Add `fcmToken` field to user documents for targeted notifications.

### Step 4: Integrate in App Lifecycle
* Initialize notifications in `main.dart` after Firebase init
* Store/update token on successful login
* Clear token on logout

### Step 5: Cloud Functions (Backend)
Create Firebase Cloud Functions:
* `onIssueCreated`: Notify department staff
* `onIssueResolved`: Notify reporter
* `onIssueReassigned`: Notify new department

### Step 6: Platform Configuration
* Android: Update `AndroidManifest.xml` with notification channel
* iOS: Add notification capabilities in Xcode

## Notification Types
| Event | Recipients | Priority |
|-------|------------|----------|
| New issue created | Department staff + managers | Normal/High based on priority |
| Issue resolved | Original reporter | Normal |
| Issue reassigned | New department staff | Normal |
| Urgent issue created | All admins | High |

## Cost Estimate
### Firebase Cloud Messaging
* **FREE** - FCM has no cost for sending notifications

### Firebase Cloud Functions
* **Free tier**: 2M invocations/month, 400K GB-seconds compute
* **Estimated usage**: ~500-2000 notifications/month for a single hotel = **FREE**
* **Beyond free tier**: $0.40 per million invocations

### Firestore (existing)
* Token storage adds minimal reads/writes (~1 per login)
* **Negligible additional cost**

### Total Estimated Cost: **$0/month**
For a single hotel operation with typical usage (a few hundred issues/month), the entire notification system will fit comfortably within Firebase's free tier.
### Cost Scaling
If scaled to multiple hotels or high volume:
* 10,000 notifications/month: Still FREE
* 100,000 notifications/month: ~$0.04/month
* 1,000,000 notifications/month: ~$0.40/month

## Files to Create/Modify
**New files:**
* `lib/services/notification_service.dart`
* `functions/index.js` (Cloud Functions)
**Modified files:**
* `pubspec.yaml` (add dependencies)
* `lib/main.dart` (initialize notifications)
* `lib/services/auth_service.dart` (store/clear token)
* `lib/models/user_model.dart` (add fcmToken field)
* `android/app/src/main/AndroidManifest.xml` (notification config)

## Timeline Estimate
* Flutter client implementation: 2-3 hours
* Cloud Functions setup: 1-2 hours
* Testing & refinement: 1-2 hours
* **Total: 4-7 hours**
