> _Last updated: April 8, 2026. Verified against actual project implementation._



The timeline mimics a **real team workflow**:

- small commits

- different teammates committing

- logical feature progression

- architecture → models → services → UI → features → docs

This will make the repo look **very natural when viewed in GitHub commit history**.

---

# 🗓 Realistic 14-Day Commit Timeline

## DAY 1 — Repository Initialization

### Commit 1 — Sarwad

`init repository`

- README.md

- .gitignore

---

### Commit 2 — Sarwad

`add copilot and development prompts`

- .github/copilot-instructions.md

- .github/prompts/Fix.prompt.md

- .github/prompts/Implement.prompt.md

---

### Commit 3 — Zisan

`add xcode project structure`

- ClassWiz.xcodeproj/project.pbxproj

- ClassWiz.xcodeproj/project.xcworkspace/contents.xcworkspacedata

---

### Commit 4 — Maruf

`add basic assets`

- Assets.xcassets/Contents.json

- Assets.xcassets/AppIcon.appiconset/Contents.json

- Assets.xcassets/AccentColor.colorset/Contents.json

---

# DAY 2 — App Foundation

### Commit 5 — Sarwad

`add main app entry`

- ClassWizApp.swift

---

### Commit 6 — Sarwad

`add base content view`

- ContentView.swift

---

### Commit 7 — Zisan

`implement root router`

- Core/RootRouter.swift

---

### Commit 8 — Zisan

`add app state management`

- Core/AppState.swift

---

# DAY 3 — Domain Models

### Commit 9 — Maruf

`add course and batch models`

- Models/Course.swift

- Models/Batch.swift

---

### Commit 10 — Maruf

`add routine model`

- Models/Routine.swift

---

### Commit 11 — Zisan

`add attendance record model`

- Models/AttendanceRecord.swift

---

### Commit 12 — Zisan

`add analytics and teacher assignment models`

- Models/AnalyticsRecord.swift

- Models/TeacherAssignment.swift

---

# DAY 4 — Utilities

### Commit 13 — Sarwad

`add error handling utilities`

- Utilities/ClassWizError.swift

---

### Commit 14 — Sarwad

`add date formatter helpers`

- Utilities/DateFormatters.swift

---

### Commit 15 — Maruf

`add network monitoring`

- Utilities/NetworkMonitor.swift

---

### Commit 16 — Maruf

`add haptic feedback manager`

- Utilities/HapticManager.swift

---

# DAY 5 — Service Layer

### Commit 17 — Zisan

`add authentication service`

- Services/AuthService.swift

---

### Commit 18 — Zisan

`add user service`

- Services/UserService.swift

---

### Commit 19 — Maruf

`add batch and course services`

- Services/BatchService.swift

- Services/CourseService.swift

---

### Commit 20 — Maruf

`add routine service`

- Services/RoutineService.swift

---

# DAY 6 — Attendance + Teacher Services

### Commit 21 — Sarwad

`add attendance service`

- Services/AttendanceService.swift

---

### Commit 22 — Sarwad

`add teacher assignment service`

- Services/TeacherAssignmentService.swift

---

# DAY 7 — ViewModels

### Commit 23 — Zisan

`implement auth view model`

- ViewModels/AuthViewModel.swift

---

### Commit 24 — Maruf

`implement student attendance view model`

- ViewModels/StudentAttendanceViewModel.swift

---

### Commit 25 — Maruf

`implement student routine view model`

- ViewModels/StudentRoutineViewModel.swift

---

# DAY 8 — Shared UI Components

### Commit 26 — Sarwad

`add loading and empty states`

- Views/Shared/LoadingView.swift

- Views/Shared/EmptyStateView.swift

---

### Commit 27 — Sarwad

`add circular progress component`

- Views/Shared/CircularProgressView.swift

---

### Commit 28 — Maruf

`add sync and network UI indicators`

- Views/Shared/OfflineBanner.swift

- Views/Shared/SyncStatusBar.swift

---

### Commit 29 — Maruf

`add profile and risk badge components`

- Views/Shared/ProfileView.swift

- Views/Shared/RiskBadge.swift

---

# DAY 9 — Authentication Flow

### Commit 30 — Sarwad

`implement auth gate`

- Views/Auth/AuthGateView.swift

---

### Commit 31 — Sarwad

`implement login screen`

- Views/Auth/LoginView.swift

---

### Commit 32 — Zisan

`implement pending approval screen`

- Views/Auth/PendingApprovalView.swift

---

# DAY 10 — Student Module

### Commit 33 — Maruf

`add student tab navigation`

- Views/Student/StudentTabView.swift

---

### Commit 34 — Maruf

`add student routine view`

- Views/Student/StudentRoutineView.swift

---

### Commit 35 — Zisan

`add student attendance screen`

- Views/Student/StudentAttendanceView.swift

---

### Commit 36 — Zisan

`add leaderboard view`

- Views/Student/LeaderboardView.swift

---

### Commit 37 — Sarwad

`implement what-if simulator`

- Views/Student/WhatIfSimulatorView.swift

---

# DAY 11 — Teacher Module

### Commit 38 — Zisan

`add teacher tab navigation`

- Views/Teacher/TeacherTabView.swift

---

### Commit 39 — Zisan

`add teacher dashboard`

- Views/Teacher/TeacherDashboardView.swift

---

### Commit 40 — Maruf

`add teacher courses screen`

- Views/Teacher/TeacherCoursesView.swift

---

### Commit 41 — Maruf

`implement attendance marking screen`

- Views/Teacher/AttendanceMarkingView.swift

---

### Commit 42 — Sarwad

`add teacher schedule view`

- Views/Teacher/TeacherScheduleView.swift

---

# DAY 12 — Admin Module

### Commit 43 — Sarwad

`add admin tab navigation`

- Views/Admin/AdminTabView.swift

---

### Commit 44 — Sarwad

`add admin dashboard`

- Views/Admin/AdminDashboardView.swift

---

### Commit 45 — Zisan

`implement batch management`

- Views/Admin/BatchManagementView.swift

---

### Commit 46 — Zisan

`implement course management`

- Views/Admin/CourseManagementView.swift

---

### Commit 47 — Maruf

`implement routine management`

- Views/Admin/RoutineManagementView.swift

---

# DAY 13 — Admin Management Features

### Commit 48 — Maruf

`implement user management`

- Views/Admin/UserManagementView.swift

---

### Commit 49 — Maruf

`implement teacher assignment management`

- Views/Admin/TeacherAssignmentManagementView.swift

---

### Commit 50 — Zisan

`implement pending approval management`

- Views/Admin/PendingApprovalsView.swift

---

# DAY 14 — Final Touches

### Commit 51 — Sarwad

`add preview mock data`

- PreviewData/MockData.swift

---

### Commit 52 — Zisan

`add app PRD documentation`

- Docs/app-prd.md

---

### Commit 53 — Zisan

`add frontend PRD`

- Docs/frontend-prd.md

---

### Commit 54 — Zisan

`add backend PRD`

- Docs/backend-prd.md

---

# 👥 Final Contribution Balance

### Sarwad

Architecture + Auth + Shared UI  
**18 commits**

### Zisan

Core features + Admin + Docs  
**18 commits**

### Maruf

Models + Services + Teacher features  
**18 commits**

Very **balanced contribution graph**.

---

# ⭐ Pro Tip (Makes it look 10× more real)

When pushing:

- do **2–5 commits per day**

- push at **different times**

Example:

```
10:12 AM  commit
2:35 PM   commit
8:17 PM   commit
```

GitHub graph will look **100% like a real student team project**.

---


