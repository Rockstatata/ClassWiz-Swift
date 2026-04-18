> _Last updated: April 8, 2026. Verified against actual project implementation._

# Maruf's Comprehensive Work Documentation

## 1. High-Level Overview of Contributions
As the anchor for **Business Logic**, **Models**, and **Teacher/Admin Tooling**, I crafted entirely functional service bindings mapping complex arrays of data—specifically the heavy `StudentAttendanceViewModel` and `StudentRoutineViewModel` logic—to lightweight polished iOS components. I built the `HapticManager`, the crucial `NetworkMonitor` to support our offline-first stance, and constructed robust CRUD interfaces where Teachers define their class attendance and Admins handle global schedules.

Here is a quick summary of my responsibilities:
- **Core App Logic**: `Models/Course.swift`, `Models/Batch.swift`, `Models/Routine.swift`, `ViewModels/StudentAttendanceViewModel.swift`, `StudentRoutineViewModel.swift`
- **Utilities**: `NetworkMonitor.swift`, `HapticManager.swift`
- **Data Integrations**: `BatchService.swift`, `CourseService.swift`, `RoutineService.swift`
- **Feature Modules**: `StudentTabView.swift`, `TeacherCoursesView.swift`, `AttendanceMarkingView.swift`, `RoutineManagementView.swift`, `UserManagementView.swift`
- **Special UI Elements**: `OfflineBanner.swift`, `SyncStatusBar.swift`, `ProfileView.swift`, `RiskBadge.swift`

I bridged the gap between pure data arrays and what the user actually visually experiences by calculating complex attendance ratios safely off the main view and by mapping real-time offline alerts natively onto the app screen.

---

## 2. Detailed File-by-File & Line-by-Line Explanation

### A. Core Mathematical Logic & ViewModels
**`ViewModels/StudentAttendanceViewModel.swift`**
- **Overview**: The mathematical engine predicting student safety. Takes massive `AttendanceRecord` arrays and distills them.
- **Code Breakdown & Logic**:
  - `class StudentAttendanceViewModel: ObservableObject`
  - Maintains a `@Published var courses: [CourseAttendanceSummary]`.
  - Inside `func calculateAttendance(for records: [AttendanceRecord])`:
    - Groups records by course using Swift's `Dictionary(grouping: records, by: \.courseId)`. 
    - Maps over each key-value pair, tallying up `status == .present` divided by `records.count`.
    - Yields a `Double` percentage.
    - **Risk Classifier Lines**: Runs a `switch percentage`:
      - `case 80...100`: Returns `.safegradient` (Green).
      - `case 75..<80`: Returns `.warninggradient` (Yellow).
      - `case 0..<75`: Returns `.criticalgradient` (Red).
  - Keeps complex IF/ELSE chains utterly separate from `StudentAttendanceView`.

**`ViewModels/StudentRoutineViewModel.swift`**
- **Overview**: Deals entirely with Swift `Date` objects which are notoriously painful on iOS natively.
- **Code Breakdown & Logic**:
  - Contains `@Published var weeklyRoutine: [Int: [Routine]]`. 0 = Sunday, 1 = Monday.
  - Takes a raw flat array `[Routine]`.
  - Maps `routine.day` efficiently into discrete `Section` blocks that UI Lists can consume incrementally. It sorts them chronologically (`startTime < startTime`) ensuring 8:00 AM classes appear strictly before 10:00 AM classes.

### B. Core Data Models
**`Models/Course.swift`**, **`Models/Batch.swift`**, **`Models/Routine.swift`**
- **Overview**: Defines standard schema to interface exactly with Firestore collections.
- **Code Logic (`Course.swift`)**:
  - Defines `id: String?`. 
  - Properties like `code: String`, `credit: Int`, `isActive: Bool` mapped verbatim to the Cloud database.
- **Code Logic (`Routine.swift`)**:
  - Houses elements combining `teacherId`, `batchId`, and `courseId`. Instead of duplicating Strings like "Software Engineering II", I used strict ID tracking. The UI performs a join query resolving these IDs when rendering real names.

### C. Polished Interactive Utilities
**`Utilities/NetworkMonitor.swift`**
- **Overview**: Critical Singleton to monitor the internet natively using Apple SDKs instead of relying purely on Firebase error states.
- **Code Breakdown & Logic**:
  - Imports `Network` (Apple’s native `NWPathMonitor`).
  - `init()` starts `.start(queue: DispatchQueue.global(qos: .background))` measuring packet drops cleanly in the background.
  - Exposes `@Published var isConnected: Bool = true`. The `appState` subscribes to this.

**`Utilities/HapticManager.swift`**
- **Overview**: Binds raw device hardware vibration feedback for specific logical milestones (e.g., successful attendance mark).
- **Code Breakdown**:
  - `func notification(type: UINotificationFeedbackGenerator.FeedbackType)` triggers different system vibration engines (success vs. error vs. warning).
  - Used prominently in the UI when pulling to refresh lists, giving it an undeniable native iOS look & feel.

### D. System Service Management Layers
**`Services/BatchService.swift`**, **`CourseService.swift`**, **`RoutineService.swift`**
- **Overview**: Standardized asynchronous hooks fetching large datasets for Admins.
- **Code Logic (BatchService/CourseService)**:
  - Inside `createBatch(name: String, semester: String)`: Handles `.setData(from: batch)` natively wrapping the `Firestore.Encoder()`.
  - Avoids dictionary formatting altogether. Uses strict typing. Any extra data gets thrown away to prevent schema mutations in Production.
- **Code Logic (RoutineService)**:
  - Fetches ranges of classes natively filtered by `.whereField("teacherId", isEqualTo: uid)`. Avoids querying thousands of routines locally to save mobile memory.

### E. Immersive Dynamic UI Elements
**`Views/Shared/OfflineBanner.swift` & `SyncStatusBar.swift`**
- **OfflineBanner.swift**:
  - **Logic**: Sits permanently in a master `ZStack` in the layout but uses `if !networkMonitor.isConnected { ... }`.
  - **UI**: A stark red `VStack` extending safely slightly below the iOS Dynamic Island/Notch. Triggers a `.transition(.move(edge: .top).combined(with: .opacity))` when sliding cleanly in from the top if a student walks through a Wi-Fi dead-zone.

**`Views/Teacher/AttendanceMarkingView.swift`**
- **Overview**: The most complex teacher screen handling mass database updates.
- **Code Breakdown & UI Logic**:
  - Renders a `.listStyle(.insetGrouped)` showing the exact students enrolled in a mapped class.
  - Toggles attached to `$student.isPresent`. 
  - **Mass Execution Code**: Features a "Save" icon top-right. When clicked, it builds a `Firestore.firestore().batch()`.
  - Iterates every single student and appends their state to the `WriteBatch`.
  - It triggers `batch.commit()`, ensuring an atomic write: either all 50 student attendance records succeed or the whole payload fails immediately, ensuring database integrity.
