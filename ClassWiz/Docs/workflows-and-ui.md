> _Last updated: April 8, 2026. Verified against actual project implementation._

# ClassWiz Workflows & UI Details

This documentation goes deep into the workflows of the application for the three roles: **Admin**, **Teacher**, and **Student**. It details the views, lines of logic execution, and specific UI elements that the course teacher might ask about.

## 1. Authentication & Routing Workflow
When a user opens the app, the following sequence occurs:
1. `ClassWizApp.swift` initializes `AppState` and starts observing the Firebase Authentication state.
2. `RootRouter.swift` evaluates `appState.authState`. 
    - If `.unauthenticated`: Routes to `AuthGateView`, which usually encapsulates `LoginView` or sign-up flows.
    - If `.authenticated`: The `appState` will attempt to fetch `users/{userId}` to identify the role (`student, teacher, admin`).
3. **Pending Users**: If a user has no assigned role yet, they land in `PendingApprovalView` where they wait for an admin to grant permissions.
4. **Offline UI**: The entire app shares the `OfflineBanner` if `NetworkMonitor.isConnected` turns false, which slides beautifully into the screen at the top.

## 2. Student Workflow
### Primary Views
- **StudentTabView**: The tab controller hosting four main tabs: Routine, Attendance, Simulator, Leaderboard.
- **StudentRoutineView**: 
  - **Logic**: Calls `StudentRoutineViewModel.fetchRoutine(batchId:)`. Sorts classes by day and time.
  - **UI**: A list or timeline UI showing courses, times, and room numbers. Uses standard SwiftUI `List` with `Section` for days. Employs `HapticManager` for pull-to-refresh interactions.
- **StudentAttendanceView**:
  - **Logic**: Calls `StudentAttendanceViewModel.fetchAttendance(studentId:)`. Calculates attendance percentage per course. 
  - **UI**: Displayed as cards. Each card incorporates the `RiskBadge` shared component:
    - 🟢 Safe ($\ge 80\%$)
    - 🟡 Warning ($75-79\%$)
    - 🔴 Critical ($< 75\%$)
  - Uses `CircularProgressView` to visualize attendance progress. The UI handles state (Loading, EmptyStateView, Data).
- **WhatIfSimulatorView**:
  - **Logic**: Locally calculates how missing future classes will affect the student's overall attendance. Updates without writing to Firestore.
  - **UI**: Sliders and steppers allow students to add "missed classes". The UI reacts instantly by updating the projected `RiskBadge`.
- **LeaderboardView**:
  - **Optionally anonymized**. Uses generic identifiers if privacy settings are enabled.
  - **UI**: Ranked list of students in the batch based on attendance percentage.

## 3. Teacher Workflow
### Primary Views
- **TeacherTabView**: The tab controller for teachers: Dashboard, Schedule, Courses.
- **TeacherDashboardView**:
  - **Logic**: Aggregates all ongoing classes for the current day based on `TeacherAssignmentService`.
  - **UI**: Action-oriented list view highlighting classes happening today.
- **AttendanceMarkingView**:
  - **Logic**: Initiates a write to the `attendance/{attendanceId}` collection. Only authors changes corresponding to `status` (Present, Absent). The write is restricted via Firestore Security Rules to the authenticated `teacherId`.
  - **UI**: A modal or full-screen view listing all students for a specific batch/course. Toggle switches or segmented controls for marking attendance. Contains a "Save" button that disables when `appState.isOffline` is true to prevent conflicts (or saves locally depending on offline preference). 
- **TeacherCoursesView**:
  - Shows assigned courses. Tapping a course navigates into course analytics, showing average attendance across the batch.

## 4. Admin Workflow
### Primary Views
- **AdminTabView**: The tab controller for system administration.
- **AdminDashboardView**:
  - **UI**: Quick stat overview (Total Students, Total Teachers, Pending Approvals) using grid layouts.
- **UserManagementView & PendingApprovalsView**:
  - **Logic**: Reads global `users` collection. Enables the Admin to assign roles to users who recently signed up.
  - **UI**: Searchable list view with `role` pickers or "Approve/Reject" buttons.
- **CRUD Views 
  (`CourseManagementView`, `BatchManagementView`, `RoutineManagementView`)**:
  - **Logic**: Perform Create, Read, Update, Delete queries using `CourseService`, `BatchService`, and `RoutineService`.
  - **UI**: Form-based modal sheets for adding items mapping out `code`, `credit`, `semesterId`, etc. Uses `TextField`, `Picker`, and `DatePicker`.

## UI/UX Best Practices Implemented
- **Offline First**: All `fetch*` methods are optimized by setting Firestore's persistence to `true`. List states persist across app loads without requiring a fresh network request.
- **Declarative & Thin Views**: Complex data mappings (e.g., calculating risk colors or formatting date ranges from Firebase Timestamps) happen in the ViewModels and Services. `RiskBadge` simply takes a `Percentage` struct and outputs colors (`Color.green`, `Color.yellow`, `Color.red`).
- **Standardized Look**: Uses `Theme.swift` for unified styling. Accent colors adapt gracefully to Apple's Dark Mode, adhering to `@Environment(\.colorScheme)`.
- **Feedback Mechanisms**: Incorporates `CircularProgressView` for long-running Firestore tasks, `EmptyStateView` when queries return no documents, and `SyncStatusBar` conveying sync success to users. 
