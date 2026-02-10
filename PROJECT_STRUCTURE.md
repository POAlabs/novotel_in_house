# Novotel Westlands In House - Project Structure

## Overview
Internal operations system for Novotel Westlands Nairobi hotel staff to report and manage facility issues.

## Architecture

```
lib/
├── main.dart                    # App entry point
├── splash_screen.dart           # Initial splash screen
│
├── config/
│   └── routes.dart              # Centralized routing configuration
│
├── services/
│   └── auth_service.dart        # Firebase authentication logic
│
├── widgets/
│   └── custom_text_field.dart   # Reusable text input widget
│
└── screens/
    ├── auth/
    │   └── sign_in_page.dart    # User authentication
    │
    └── dashboards/
        ├── employee_dashboard.dart   # Employee role dashboard
        ├── manager_dashboard.dart    # Manager role dashboard
        └── admin_dashboard.dart      # System admin dashboard
```

## User Roles

### 1. Employee
- View issues in own department
- Report new issues
- Mark issues as resolved

### 2. Manager
- All employee permissions
- View all issues in managed department
- Oversee department operations

### 3. System Admin (IT Team)
- View ALL issues across departments
- Manage users (add, remove, assign roles)
- Access system settings
- Kill switch to disable app

## Development Credentials

**Admin:**
- Email: `admin@novotel.com`
- Password: `password123`

**Manager:**
- Email: `manager@novotel.com`
- Password: `password123`

**Employee:**
- Email: `employee@novotel.com`
- Password: `password123`

## Firebase Setup (TODO)

The app is configured for Firebase Authentication and Firestore, but implementation is pending:

1. Add Firebase configuration files
2. Uncomment Firebase code in `auth_service.dart`
3. Create Firestore collections:
   - `users` - user profiles with roles
   - `issues` - reported issues
   - `departments` - department information

## Navigation Flow

```
Splash Screen (2.5s)
    ↓
Sign In Page
    ↓
Authentication
    ├── admin@novotel.com → Admin Dashboard
    ├── manager@novotel.com → Manager Dashboard
    └── employee@novotel.com → Employee Dashboard
```

## Code Style

- **Comments**: Every major code block is commented
- **Structure**: Small, focused files (< 350 lines)
- **Naming**: Clear, descriptive names
- **Widgets**: Broken into small, reusable methods
- **Services**: Separated business logic from UI

## Next Steps

1. Implement Firebase authentication
2. Build issue reporting UI
3. Create hotel floor visualization
4. Add real-time notifications
5. Implement user management for admins
