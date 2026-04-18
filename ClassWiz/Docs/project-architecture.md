> _Last updated: April 8, 2026. Verified against actual project implementation._

# ClassWiz Project Architecture

## Overall Program Flow
1. **Entry Point** (`ClassWizApp.swift`): Configures Firebase, sets up offline persistence, and initializes environmental states (`AppState`, `NetworkMonitor`). The root view is `RootRouter()`.
2. **Routing** (`Core/RootRouter.swift`): Acts as the gatekeeper. It checks the user's authentication state. 
   - If not authenticated, routes to `AuthGateView`.
   - If authenticated, checks `appState.userRole`. Routes to the respective tab view (`StudentTabView`, `TeacherTabView`, `AdminTabView`) based on the role. Unassigned/pending users might go to `PendingApprovalView`.
3. **Role-Based Workflows**:
   - **Student**: Appears in `StudentTabView`. They can view their routines (`StudentRoutineView`), attendance (`StudentAttendanceView`), simulated what-if scenarios (`WhatIfSimulatorView`), and their peers (`LeaderboardView`).
   - **Teacher**: Appears in `TeacherTabView`. They manage their specific courses (`TeacherCoursesView`), view schedule (`TeacherScheduleView`), and mark attendance (`AttendanceMarkingView`).
   - **Admin**: Appears in `AdminTabView`. They control the system via management views like `CourseManagementView`, `BatchManagementView`, `RoutineManagementView`, `UserManagementView`, etc.

## Directory Structure and File Roles

* **ClassWizApp.swift**: The app entry point. Inits Firebase components.
* **ContentView.swift**: A placeholder or secondary view, generally superseded by `RootRouter`.
* **GoogleService-Info.plist**: Firebase configuration file.

### App & Assets
* **Assets.xcassets**: Contains dynamic colors (AccentColor), app icons, and other images used in the UI.

### Core
* **AppState.swift**: Global state management, particularly for holding authenticated user info, role, and offline status.
* **RootRouter.swift**: Top-level navigator that routes authenticated and unauthenticated journeys.

### Models
Central definitions mapping to Firebase documents.
* **Course.swift**, **Batch.swift**, **Routine.swift**, **TeacherAssignment.swift**, **AttendanceRecord.swift**, **AnalyticsRecord.swift**: Swift `Codable` structs for Firestore parsing.

### Services
Acts as the Data Access layer. Wrapper around Firestore.
* **AuthService.swift**: Handles sign-in, sign-up, session, and role fetching.
* **AttendanceService.swift**: Reads/writes attendance marking logic.
* **RoutineService.swift**: Fetches class schedules by batch or teacher.

### Utilities
* **ClassWizError.swift**: Enum/Error struct for robust error feedback.
* **DateFormatters.swift**: Standardizes time/date strings across the UI.
* **HapticManager.swift**: Triggers vibrations for UI events like success or error.
* **NetworkMonitor.swift**: Uses `NWPathMonitor` to track offline/online states.

### ViewModels
MVVM logic separated from views.
* **AuthViewModel.swift**: Connects Auth UI with `AuthService`.
* **StudentAttendanceViewModel.swift**: Aggregates attendance data (calculating percentages and risks).
* **StudentRoutineViewModel.swift**: Formats routines logically by day/time.

### Views
* **Admin**: Contains all the operational UI for admins. Shows lists of users, manages routines, etc.
* **Auth**: Contains `LoginView`, `AuthGateView`, `PendingApprovalView`.
* **Shared**: UI components shared across roles, like `RiskBadge` (shows 🟢 Safe, 🔴 Critical), `OfflineBanner`, `LoadingView`, `ProfileView`.
* **Student**: The specific UI flows for student end-users. Includes rich visualizations for "What-if" scenarios.
* **Teacher**: UI for teachers. Includes `AttendanceMarkingView` which is highly sensitive due to role-based write rules.

## Data Integrity and Persistence
ClassWiz heavily relies on Firebase's offline capabilities. `isPersistenceEnabled` is `true`. Reading data triggers listeners, letting UI elements react to backend changes immediately or when connection restores.
