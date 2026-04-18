> _Last updated: April 8, 2026. Verified against actual project implementation._

# Zisan's Comprehensive Work Documentation

## 1. High-Level Overview of Contributions
As the orchestrator of **Data Models** and **Security Flows** (Routing/Auth), my role ensures users see only what they are legally permitted to see under Role-Based Access Control (RBAC). I wrote the entire global routing logic (`RootRouter`), handled mapping Firebase documents to precise Swift `Codable` structs, and completely built out the backend documentation strategy (`backend-prd.md`). I also focused on complex teacher endpoints (`TeacherDashboardView`) and student competitive views (`LeaderboardView`).

Here is a summary of my responsibilities:
- **Routing & State**: `project.pbxproj`, `RootRouter.swift`, `AppState.swift`
- **Models**: `AttendanceRecord.swift`, `AnalyticsRecord.swift`, `TeacherAssignment.swift`
- **Auth & Database Services**: `AuthService.swift`, `UserService.swift`, `AuthViewModel.swift`
- **Interactive UIs**: `PendingApprovalView.swift`, `StudentAttendanceView.swift`, `LeaderboardView.swift`, `TeacherTabView.swift`, `BatchManagementView.swift`, `CourseManagementView.swift`
- **Documentation**: Entire PRD suites mapping developer intentions.

By separating the authentication routing into a pure state-driven construct and standardizing how Swift communicates with Firebase Collections, I secured the foundation that the rest of the team built upon.

---

## 2. Detailed File-by-File & Line-by-Line Explanation

### A. Core Routing & State Handlers
**`Core/RootRouter.swift`**
- **Overview**: The "traffic light" of the application. Evaluates global states dynamically.
- **Code Breakdown/Logic**:
  - Starts with `@EnvironmentObject var appState: AppState`. This binds the entire view's layout structure to whatever the singleton decides.
  - `switch appState.authState`:
    - `case .unauthenticated`: Renders `AuthGateView`.
    - `case .authenticated`: Immediately drops into *another* `switch state` based on `appState.userRole`.
    - `case .student`: Shows `StudentTabView()`, `case .teacher`: Shows `TeacherTabView()`, `case .admin`: Shows `AdminTabView()`.
    - `case .pending`: Renders the `PendingApprovalView()`.
  - **Security aspect**: Users cannot bypass this. If a user tries to alter their role locally without an admin approving it in Firebase, the snapshot listener on `appState` will instantly overwrite it and throw them back to `.pending`.

**`Core/AppState.swift`**
- **Overview**: An `@MainActor` observable object, guaranteeing that UI changes bound to it run exclusively on the main thread (preventing crashes).
- **Code Breakdown**:
  - `Auth.auth().addStateDidChangeListener { auth, user in ... }`. This closure fires whenever a token expires or a user logs in.
  - As soon as a user logs in (`user != nil`), it triggers `fetchRole()`, reaching out to `users/{uid}`. This resolves their permission tier asynchronously, publishing changes to `@Published var userRole`.

### B. Core Data Mapping Models
**`Models/AttendanceRecord.swift`**
- **Overview**: Struct defining how an individual attendance tally is constructed.
- **Code Breakdown**:
  - `struct AttendanceRecord: Identifiable, Codable`. `Codable` translates raw JSON from Firebase exactly to the struct's parameters.
  - `@DocumentID var id: String?`: Automatically pulls the Firestore `documentID` into the struct upon mapping.
  - Properties like `studentId: String`, `courseId: String`, `date: Date`, `status: AttendanceStatus`. This creates standard, predictable objects instead of dealing with loose Strings from Dictionary casting.

**`Models/TeacherAssignment.swift`**
- **Overview**: Resolves many-to-many database relationships.
- **Code Logic**: A teacher holds an array of `courseId`s and `batchId`s dynamically linked, keeping actual course data out of the user object (preventing data duplication).

### C. The Authentication Pipeline
**`Services/AuthService.swift` & `UserService.swift`**
- **Overview**: Wrapped implementations of `FirebaseAuth`.
- **Code Logic (AuthService)**:
  - `func signIn(email: String, password: String) async throws`. The `async throws` replaces ugly closure-based code (`completion: @escaping (Error?)`).
  - Implements translation wrappers. If Firebase throws an error `FIRAuthErrorCode.wrongPassword`, my service intercepts it and throws `ClassWizError.unauthorized("Incorrect password")`, which is much prettier for the UI.
- **Code Logic (UserService)**:
  - `func fetchUser(uid: String)` reaches out explicitly to the NoSQL `users` collection to pull metadata.
  - `func updateUserRole(uid: String, role: Role)` enables `admin` accounts to alter another user’s role status via UI triggers in `UserManagementView`.

**`ViewModels/AuthViewModel.swift`**
- **Code Breakdown**:
  - `@Published var email = ""` and `@Published var password = ""`. As the user taps keys in `LoginView`, these update instantly.
  - The `login()` method wraps the service call inside a `do-catch` block, flagging `isLoading = true` before the call and `isLoading = false` via a `defer {}` block (a Swift feature making sure it runs whether it crashes or succeeds).

### D. Deep Interactive UI Modules
**`Views/Student/StudentAttendanceView.swift` & `LeaderboardView.swift`**
- **StudentAttendanceView**:
  - **Logic**: I incorporated the view models built by Maruf here. The UI dynamically loops `ForEach(viewModel.courses)` delivering a card stack of attendance progress via the shared `CircularProgressView`.
- **LeaderboardView**:
  - **Logic**: A core feature. It arrays `users` filtered by `appState.currentBatch`. `List(sortedStudents) { student in ... }` lines up the classmates.
  - **Security Filter Lines**: To prevent data leaks, the database queries strictly append `.whereField("role", isEqualTo: "student")` ensuring teachers don’t artificially show up queued in competitive student lists.

**`Views/Admin/BatchManagementView.swift`**
- **Overview**: Admin CRUD panels.
- **UI Logic**: Employs Swift's `.sheet()` modifier for adding new batches. Handles `.onDelete(perform: deleteBatch)` inside a `ForEach` loop, which smoothly animates row destruction natively in iOS while firing async background calls to `BatchService` to wipe the DB record.
