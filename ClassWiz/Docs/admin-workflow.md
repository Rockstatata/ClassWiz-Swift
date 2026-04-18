# ClassWiz — Admin Workflow Analysis

## Overview

The Admin module in **ClassWiz** acts as the central command center for managing institutional data, users, and schedules. Guided by Role-Based Access Control (RBAC), only users with `role == .admin` and `isApproved == true` can access the specific Admin UI hierarchy.

The admin workflow spans the complete lifecycle of adding and managing essential entities: Courses, Batches, Routines, Teachers, and Students. The architecture strictly adheres to MVVM (Model-View-ViewModel), with thin Swift Views delegating data loading and updates to specialized ViewModels, which in turn communicate with Firebase abstractly via Service singletons.

---

## 1. Frontend UI Structure

The entry point for the Admin role is **`AdminTabView`**. It features a bottom navigation bar splitting the administrative responsibilities into five separate tabs:

1. **Dashboard** (`AdminDashboardView`): A high-level overview.
2. **Courses** (`CourseManagementView`): View, Create, Update, Delete (CRUD) courses.
3. **Batches** (`BatchManagementView`): CRUD management for student batches.
4. **Routines** (`RoutineManagementView`): Scheduling the weekly routines.
5. **More** (`AdminMoreView`): A central dispatch view for:
   - Pending Approvals (`PendingApprovalsView`)
   - Teacher Assignments (`TeacherAssignmentManagementView`)
   - All Users Directory (`UserManagementView`)
   - Admin Profile configuration

### The UI Flow

*   **Initialization & Navigation:** Upon Firebase Authentication success, `AppState` determines the role. For an admin, the `RootRouter` immediately mounts `AdminTabView`.
*   **State Management:** Views are decorated with `@StateObject` ViewModels natively controlling `@Published` flags such as `isLoading` or `errorMessage` to provide immediate feedback loops via progress spinners and haptic engine responses. 
*   **Offline-First Tolerance:** Where direct reads are performed (e.g., loading lists of batches), offline cache persistence via Firestore is passively handled by the iOS SDK.

---

## 2. Backend Logics & ViewModels

Every distinct view interacts with the database exclusively via its bound `@MainActor` ViewModel. 

### Admin Dashboard Logic
The `AdminDashboardViewModel` concurrently initiates fetch requests across five distinct services (`UserService`, `CourseService`, `BatchService`, `RoutineService`, `TeacherAssignmentService`) using `async let`. It then maps and filters the raw data array in-memory to populate summary counts for Students, Teachers, Courses, and more.

### Pending User Approvals
1. **Trigger:** New users are created with `{ isApproved: false }`.
2. **ViewModel:** `PendingApprovalsViewModel.loadPendingUsers()` queries the `users` collection using `whereField("isApproved", isEqualTo: false)`.
3. **Action:** The Admin clicks "Approve".
4. **Result:** `UserService.approveUser(_:)` pushes the Boolean switch natively to `{ isApproved: true }` in Firestore, immediately unlocking the App for that user.

### Entities Management (Courses, Batches)
Admin defines the normalized master records.
*   **Courses:** `CourseManagementViewModel` calls `CourseService.create(_)`.
*   **Batches:** `BatchManagementViewModel` binds year and semester data, delegating saves to `BatchService`.

### Teacher Assignments & Routing
To support decentralized teaching responsibilities, Admins bridge relationships.
*   **`TeacherAssignmentManagementViewModel`:** Maps `Teacher` ↔ `Course` ↔ `Batch`. This is critical, as a Teacher relies exclusively on `TeacherAssignmentService` to discover which classes they manage.
*   **`RoutineManagementViewModel`:** Instructs the app when and where a given `Teacher` teaches a `Course` to a `Batch`.

---

## 3. Data Flow: Firebase JSON Fetching & Parsing

All collections are strongly typed using Swift Codable models with `@DocumentID` handling auto-assigned IDs. The mapping occurs exclusively at the `Service` layer using lightweight wrappers around Firebase iOS Native SDK queries.

### Collection Schemas & Parsing

#### `users` Collection
*   **Read Payload (JSON representation):**
    ```json
    {
      "name": "Admin User",
      "email": "admin@university.edu",
      "role": "admin",
      "isApproved": true,
      "batchId": null,
      "createdAt": "Timestamp"
    }
    ```
*   **Parsing Logic:** Mapped via `UserService` into `AppUser(id:name:email:role:batchId:isApproved:createdAt:)`.

#### `courses` Collection
*   **Read Payload:**
    ```json
    {
      "code": "CSE-321",
      "name": "Database Systems",
      "credit": 3.0,
      "isActive": true
    }
    ```
*   **Parsing Logic:** Loaded natively utilizing `try? $0.data(as: Course.self)`. Admin toggles `isActive` to archive a course.

#### `batches` Collection
*   **Read Payload:**
    ```json
    {
      "name": "CSE 3A",
      "semesterId": "Spring 2026",
      "year": 2026
    }
    ```
*   **Parsing Logic:** Handled via `try await collection.order(by: "year", descending: true).getDocuments()`. Errors in decoding gracefully bypass corrupted nodes rather than crashing the loop (`BatchService`).

#### `routines` Collection
*   **Read Payload:**
    ```json
    {
      "courseId": "db_sys_123",
      "teacherId": "teach_xyz",
      "batchId": "b_3a",
      "day": "monday",
      "startTime": "09:00",
      "endTime": "10:30",
      "room": "Room-301"
    }
    ```
*   **Parsing Flow:** Admin saves a multi-dimensional junction. Routines heavily utilize foreign keys (`courseId`, `teacherId`, `batchId`) to preserve a strict denormalized pattern optimized for Firestore document scaling constraints.

#### `teacherAssignments` Collection
*   **Read Payload:**
    ```json
    {
      "teacherId": "teach_xyz",
      "courseId": "db_sys_123",
      "batchId": "b_3a"
    }
    ```
*   **Why it Matters for Admins:** Without admins configuring these documents manually, teachers will boot into a blank app state. It represents authoritative RBAC control at the functional level.

---

## Conclusion

The Admin module is architected strictly within Apple's modern SwiftUI concurrency guidelines using `async/await` tasks instead of heavy closure indentations. By routing everything through discrete ViewModels, UI thread blockages are eliminated, and Firebase collection indexing and mapping are safely restricted from local View implementations, ensuring high security and structural integrity.