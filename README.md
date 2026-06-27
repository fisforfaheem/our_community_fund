# Our Community Fund App

A comprehensive Flutter application for managing community fund contributions and support programs, designed to digitize and streamline the process of collecting monthly payments and providing assistance to community members in need.

## Features

### Authentication
- User registration with email and password
- Secure login system
- Role-based access (Admin/Regular User)
- Password reset functionality

### Admin Features
1. Dashboard
   - Monthly summary statistics
   - Real-time overview of all contributors
   - Payment status indicators
   - Quick access to reports and settings
   - Interactive analytics charts

2. Enhanced Analytics
   - Payment trend line charts
   - Member compliance donut charts
   - Monthly trends bar charts
   - Interactive tooltips and legends
   - Color-coded current month indicators
   - Customizable date ranges

3. Payment Management
   - Record payments for individual users
   - Set standard monthly payment amount
   - Configure payment schedules
   - Track payment history
   - Bulk payment recording (coming soon)
   - Payment receipt generation (coming soon)

4. Reports and Exports
   - Monthly payment statistics
   - User compliance rates
   - Payment trends visualization
   - Export payments to CSV
   - Export user lists to CSV
   - Export monthly reports to CSV
   - Advanced data filtering
   - Custom report generation

5. User Management
   - View and search contributors
   - Monitor payment status
   - Send payment reminders
   - Track individual contribution history
   - Manage user notification preferences
   - View user activity logs

6. Settings
   - Configure payment schedules
   - Set reminder dates
   - Define grace periods
   - Manage notification settings
   - Configure email notifications
   - Set system preferences

7. Community Support Management
   - Review and process support requests
   - Allocate funds for different support programs
   - Track support disbursements
   - Generate support reports
   - Monitor program effectiveness
   - Set eligibility criteria
   - Manage emergency assistance
   - Track beneficiary history

### User Features
1. Dashboard
   - Personal payment status
   - Payment history
   - Total contributions
   - Next payment due date
   - Interactive payment charts
   - Contribution analytics

2. Profile Management
   - Update personal information
   - View payment history
   - Track total contributions
   - Manage notification preferences
   - Configure email settings

3. Enhanced Notifications
   - Customizable notification preferences
   - Payment reminders
   - Payment confirmations
   - System updates
   - Email notifications
   - In-app notifications
   - Custom notification scheduling

4. Analytics
   - Personal payment trends
   - Contribution history charts
   - Monthly payment analysis
   - Interactive visualizations
   - Payment status indicators

5. Community Support
   - View available support programs
   - Submit support requests
   - Track request status
   - Access support history
   - View eligibility criteria
   - Emergency assistance requests
   - Upload supporting documents
   - Receive status updates

## Setup Instructions

### Prerequisites
1. Flutter SDK (^3.5.4)
2. Firebase Account
3. Android Studio or VS Code
4. Git
5. Node.js (for Firebase CLI)

### Installation Steps

1. Clone the repository:
```bash
git clone [repository-url]
cd our_community_fund
```

2. Install dependencies:
```bash
flutter pub get
```

### Firebase Setup

1. Create Firebase Project:
   ```bash
   # Install Firebase CLI if not installed
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   ```

2. Firebase Console Setup:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Create Project" or select existing project
   - Enter project name and follow setup wizard
   - Enable Google Analytics (recommended)

3. Enable Authentication:
   - In Firebase Console, go to "Authentication"
   - Click "Get Started"
   - Enable "Email/Password" provider
   - Configure email templates (optional)
   - Set authorized domains

4. Set up Cloud Firestore:
   - Go to "Firestore Database"
   - Click "Create Database"
   - Choose "Start in production mode"
   - Select database location
   - Wait for database creation

5. Configure Android App:
   - In Firebase Console, click Android icon (⚙️)
   - Enter package name (from android/app/build.gradle)
   - Download google-services.json
   - Place in android/app/
   - Update build.gradle files:

   ```gradle
   // android/build.gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.3.15'
       }
   }

   // android/app/build.gradle
   apply plugin: 'com.google.gms.google-services'
   ```

6. Configure iOS App:
   - In Firebase Console, click iOS icon (⚙️)
   - Enter Bundle ID (from ios/Runner.xcodeproj/project.pbxproj)
   - Download GoogleService-Info.plist
   - Place in ios/Runner/
   - Update Podfile:
   ```ruby
   # ios/Podfile
   platform :ios, '12.0'
   ```

7. Configure Firebase (compile-time defines):
   - Copy `.env.example` to `run_dev.sh` and fill in values from Firebase Console
   - Run the app: `./run_dev.sh` or pass `--dart-define=KEY=value` flags to `flutter run`
   - See `lib/core/config/firebase_config.dart` for required define names

8. Set up Firestore Security Rules:
   ```javascript
   // In Firebase Console -> Firestore -> Rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // User profiles
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           (request.auth.uid == userId || 
            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
       }
       
       // Payments
       match /payments/{paymentId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
       }
       
       // Notifications
       match /notifications/{notificationId} {
         allow read: if request.auth != null && 
           resource.data.userId == request.auth.uid;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
       }
       
       // Settings
       match /settings/{settingId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
       }
     }
   }
   ```

9. Configure Firebase Indexes:
   ```bash
   # Create composite indexes for queries
   firebase deploy --only firestore:indexes
   ```

### Initial Admin Setup

1. Create First Admin User:
   ```bash
   # Run the app
   flutter run
   ```
   - Register a new user through the app
   - In Firebase Console:
     - Go to Firestore Database
     - Find users collection
     - Open the document for your user
     - Add field: `isAdmin: true`

2. Configure Initial Settings:
   - Log in as admin
   - Go to Settings screen
   - Set up:
     - Standard monthly amount
     - Payment due date
     - Grace period days
     - Notification preferences

### Notification Setup

1. Android Setup:
   - Update android/app/src/main/AndroidManifest.xml:
   ```xml
   <manifest>
     <!-- Permissions -->
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
     <uses-permission android:name="android.permission.VIBRATE" />
     <uses-permission android:name="android.permission.WAKE_LOCK" />
   </manifest>
   ```

2. iOS Setup:
   - Enable notifications in Xcode:
     - Open ios/Runner.xcworkspace
     - Enable "Push Notifications" capability
     - Update Info.plist:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   ```

## Running the App

1. Start the app:
```bash
flutter run
```

2. Verify Firebase Connection:
   - Check Firebase Console
   - Verify Authentication working
   - Confirm Firestore access
   - Test notifications

## Common Setup Issues

1. Firebase Connection:
   ```
   Error: [firebase/not-initialized]
   ```
   - Check `--dart-define` values in `run_dev.sh` or launch config
   - Verify google-services.json placement
   - Confirm build.gradle setup

2. Firestore Access:
   ```
   Error: PERMISSION_DENIED
   ```
   - Review security rules
   - Check user authentication
   - Verify admin privileges

3. Notification Issues:
   ```
   Error: MissingPluginException
   ```
   - Run `flutter clean`
   - Delete build folders
   - Rebuild project

## Usage Guide

### For Administrators

1. Analytics Dashboard:
   - View interactive charts
   - Monitor payment trends
   - Track compliance rates
   - Analyze monthly data
   - Export reports

2. Recording Payments:
   - Click '+' button on dashboard
   - Select user or search by name
   - Enter payment amount
   - Add optional note
   - Confirm payment

3. Managing Reports:
   - Access from analytics section
   - Select date range
   - Choose report type
   - Apply filters
   - Export to CSV

4. User Management:
   - Search and filter users
   - View payment histories
   - Send notifications
   - Manage preferences
   - Track compliance

### For Users

1. Dashboard Features:
   - View payment status
   - Check contribution history
   - Access analytics charts
   - Track payment trends
   - Monitor total contributions

2. Profile Management:
   - Update personal info
   - Set notification preferences
   - Configure email settings
   - View payment history
   - Track contributions

3. Notification Settings:
   - Customize preferences
   - Choose notification types
   - Set email preferences
   - Manage reminders
   - Configure alerts

## Database Structure

### Collections:
1. users
   - id: string
   - name: string
   - email: string
   - isAdmin: boolean
   - lastPayment: timestamp
   - totalContributions: number
   - notificationPreferences: map

2. payments
   - userId: string
   - amount: number
   - date: timestamp
   - note: string
   - recordedBy: string
   - status: string

3. notifications
   - userId: string
   - type: string
   - message: string
   - timestamp: timestamp
   - read: boolean
   - emailSent: boolean

4. notification_preferences
   - userId: string
   - paymentReminders: boolean
   - paymentConfirmations: boolean
   - systemUpdates: boolean
   - emailNotifications: boolean

5. settings
   - standardAmount: number
   - reminderDay: number
   - gracePeriodDays: number
   - lastUpdated: timestamp
   - emailSettings: map

6. support_programs
   - id: string
   - name: string
   - description: string
   - eligibilityCriteria: array
   - maxAmount: number
   - isActive: boolean
   - createdAt: timestamp
   - updatedAt: timestamp

7. support_requests
   - id: string
   - userId: string
   - programId: string
   - requestDate: timestamp
   - status: string
   - amount: number
   - description: string
   - documents: array
   - reviewedBy: string
   - reviewDate: timestamp
   - disbursementDate: timestamp

8. disbursements
   - id: string
   - requestId: string
   - userId: string
   - amount: number
   - date: timestamp
   - method: string
   - approvedBy: string
   - notes: string

## Security Considerations

1. Authentication:
   - Email verification
   - Secure password requirements
   - Session management

2. Data Access:
   - Role-based permissions
   - Firestore security rules
   - Data validation

3. Payment Security:
   - Transaction records
   - Admin approval
   - Audit trail

## Troubleshooting

Common Issues:
1. Firebase Connection:
   - Check configuration files
   - Verify internet connection
   - Confirm Firebase project settings

2. Notifications:
   - Check device permissions
   - Verify Firebase setup
   - Test notification settings

3. Payment Recording:
   - Verify admin privileges
   - Check Firestore rules
   - Confirm user data

## Support

For technical support or feature requests:
1. Submit issues on GitHub
2. Contact system administrator
3. Check documentation

## Future Enhancements

Planned features:
1. Payment gateway integration
2. Mobile money integration
3. Bulk payment processing
4. Enhanced reporting tools
5. Advanced analytics features
6. PDF report generation
7. Excel export support
8. Custom dashboard widgets
9. Advanced search filters
10. Automated compliance reports
11. Enhanced support request workflow
12. Digital disbursement integration
13. Support program analytics
14. Beneficiary tracking system
15. Emergency response system

## Architecture

This project follows **Clean Architecture** with three layers under `lib/`:

| Layer | Path | Responsibility |
|-------|------|----------------|
| **Domain** | `lib/domain/` | Entities, repository interfaces, use cases (no Firebase imports) |
| **Data** | `lib/data/` | Data sources, DTOs, repository implementations |
| **Presentation** | `lib/presentation/` | Screens, providers, UI wiring via use cases |

Legacy screens under `lib/screens/` and `lib/services/` remain as thin adapters during incremental migration. Auth flows (login, register, profile) are fully migrated.

Dependency injection is wired in `lib/presentation/providers/app_providers.dart` and registered in `main.dart` via `MultiProvider`.

## Firebase Configuration & Secrets

Firebase credentials are **not** committed. They are passed at compile time via `--dart-define`:

1. Copy `.env.example` values into `run_dev.sh` (gitignored).
2. Run locally: `./run_dev.sh` or pass defines manually to `flutter run` / `flutter build`.

**Security note:** Firebase client API keys ship inside every installed app and are protected by Firestore Security Rules, not by hiding them in git. If keys were ever exposed in git history, rotate them in the [Firebase Console](https://console.firebase.google.com/) for true remediation. Git history was sanitized to remove `firebase_options.dart`, but cached GitHub blobs may persist until garbage-collected.

## Release Logging

Use `AppLogger` (`lib/core/utils/logger.dart`) instead of `print()`. Debug/info logs are suppressed in release builds; FCM tokens and other sensitive values are never logged.
