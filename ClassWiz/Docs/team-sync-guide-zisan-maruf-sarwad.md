# ClassWiz Push Guide (Zisan, Maruf, Sarwad)

## Source and Target

- Latest local source: `G:/KUET/Projects/SwiftIOS/ClassWiz/ClassWiz`
- GitHub repo working copy: `G:/KUET/Projects/SwiftIOS/ClassWiz-Swift/ClassWiz`
- Current Git branch (repo): `zisan`

## Purpose

Use this guide to push remaining non-markdown updates safely with minimal merge conflicts.

## Team Split (Requested)

### Maruf: Teacher Part

Branch name:

- `sync/maruf-teacher`

Exact files to copy and push:

- `ClassWiz/Services/TeacherAssignmentService.swift`
- `ClassWiz/Views/Teacher/AttendanceMarkingView.swift`
- `ClassWiz/Views/Teacher/TeacherAssignmentsView.swift`
- `ClassWiz/Views/Teacher/TeacherCoursesView.swift`
- `ClassWiz/Views/Teacher/TeacherDashboardView.swift`
- `ClassWiz/Views/Teacher/TeacherScheduleView.swift`
- `ClassWiz/Views/Teacher/TeacherTabView.swift`

### Sarwad: Admin Part

Branch name:

- `sync/sarwad-admin`

Exact files to copy and push:

- `ClassWiz/Views/Admin/AdminDashboardView.swift`
- `ClassWiz/Views/Admin/AdminTabView.swift`
- `ClassWiz/Views/Admin/BatchManagementView.swift`
- `ClassWiz/Views/Admin/CourseManagementView.swift`
- `ClassWiz/Views/Admin/PendingApprovalsView.swift`
- `ClassWiz/Views/Admin/RoutineManagementView.swift`
- `ClassWiz/Views/Admin/TeacherAssignmentManagementView.swift`
- `ClassWiz/Views/Admin/UserManagementView.swift`

### Sarwad: Remaining Files (After Maruf Teacher + Sarwad Admin)

Branch name:

- `sync/sarwad-remaining`

Exact remaining files to copy and push (58):

- `ClassWiz/.gitignore`
- `ClassWiz/Assets.xcassets/AccentColor.colorset/Contents.json`
- `ClassWiz/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `ClassWiz/Assets.xcassets/Contents.json`
- `ClassWiz/ClassWiz.xcodeproj/project.pbxproj`
- `ClassWiz/ClassWiz.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- `ClassWiz/ClassWiz.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ClassWiz/ClassWiz.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
- `ClassWiz/ClassWizApp.swift`
- `ClassWiz/ContentView.swift`
- `ClassWiz/Core/RootRouter.swift`
- `ClassWiz/Docs/screen-cods.txt`
- `ClassWiz/GoogleService-Info.plist`
- `ClassWiz/Models/AttendanceRecord.swift`
- `ClassWiz/Models/Batch.swift`
- `ClassWiz/Models/Course.swift`
- `ClassWiz/Models/CWNotification.swift`
- `ClassWiz/Models/Routine.swift`
- `ClassWiz/PreviewData/MockData.swift`
- `ClassWiz/Resources/Theme.swift`
- `ClassWiz/Services/AttendanceService.swift`
- `ClassWiz/Services/BatchService.swift`
- `ClassWiz/Services/CloudinaryService.swift`
- `ClassWiz/Services/CourseService.swift`
- `ClassWiz/Services/NotificationService.swift`
- `ClassWiz/Services/RoutineService.swift`
- `ClassWiz/Services/UserService.swift`
- `ClassWiz/test.swift`
- `ClassWiz/test_cloudinary.swift`
- `ClassWiz/Utilities/ClassWizError.swift`
- `ClassWiz/Utilities/DateFormatters.swift`
- `ClassWiz/Utilities/HapticManager.swift`
- `ClassWiz/Utilities/NetworkMonitor.swift`
- `ClassWiz/ViewModels/AuthViewModel.swift`
- `ClassWiz/ViewModels/StudentAttendanceViewModel.swift`
- `ClassWiz/ViewModels/StudentRoutineViewModel.swift`
- `ClassWiz/Views/Auth/AuthGateView.swift`
- `ClassWiz/Views/Auth/LoginView.swift`
- `ClassWiz/Views/Auth/PendingApprovalView.swift`
- `ClassWiz/Views/Shared/CircularProgressView.swift`
- `ClassWiz/Views/Shared/ClassWizScreen.swift`
- `ClassWiz/Views/Shared/CWSearchBar.swift`
- `ClassWiz/Views/Shared/EmptyStateView.swift`
- `ClassWiz/Views/Shared/LoadingView.swift`
- `ClassWiz/Views/Shared/NotificationView.swift`
- `ClassWiz/Views/Shared/OfflineBanner.swift`
- `ClassWiz/Views/Shared/ProfileView.swift`
- `ClassWiz/Views/Shared/RiskBadge.swift`
- `ClassWiz/Views/Shared/SyncStatusBar.swift`
- `ClassWiz/Views/Shared/TopRoundedRectangle.swift`
- `ClassWiz/Views/Student/LeaderboardView.swift`
- `ClassWiz/Views/Student/StudentAssignmentsView.swift`
- `ClassWiz/Views/Student/StudentAttendanceView.swift`
- `ClassWiz/Views/Student/StudentCoursesAndClassesView.swift`
- `ClassWiz/Views/Student/StudentRoutineView.swift`
- `ClassWiz/Views/Student/StudentTabView.swift`
- `ClassWiz/Views/Student/WhatIfSimulatorView.swift`

Local file not to commit:

- `ClassWiz/.env`

## Standard Push Steps (Everyone)

Run from repo root: `G:/KUET/Projects/SwiftIOS/ClassWiz-Swift`

1. `git checkout main`
2. `git pull origin main`
3. `git checkout -b <your-branch>`
4. Copy only assigned files from source folder to repo folder.
5. Stage only assigned files.
6. Verify staged files:
   - `git diff --staged --name-only`
7. Commit:
   - `git commit -m "sync: <your-scope> from latest ClassWiz local"`
8. Push:
   - `git push -u origin <your-branch>`
9. Open PR to `main`.

## Ready Commands: Maruf

```powershell
Set-Location "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift"
git checkout main
git pull origin main
git checkout -b sync/maruf-teacher

$src = "G:/KUET/Projects/SwiftIOS/ClassWiz/ClassWiz"
$dst = "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift/ClassWiz"
$files = @(
  "Services/TeacherAssignmentService.swift",
  "Views/Teacher/AttendanceMarkingView.swift",
  "Views/Teacher/TeacherAssignmentsView.swift",
  "Views/Teacher/TeacherCoursesView.swift",
  "Views/Teacher/TeacherDashboardView.swift",
  "Views/Teacher/TeacherScheduleView.swift",
  "Views/Teacher/TeacherTabView.swift"
)

foreach($f in $files){
  Copy-Item -Path (Join-Path $src $f) -Destination (Join-Path $dst $f) -Force
}

git add ClassWiz/Services/TeacherAssignmentService.swift ClassWiz/Views/Teacher/*.swift
git diff --staged --name-only
git commit -m "sync: teacher module updates"
git push -u origin sync/maruf-teacher
```

## Ready Commands: Sarwad

```powershell
Set-Location "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift"
git checkout main
git pull origin main
git checkout -b sync/sarwad-admin

$src = "G:/KUET/Projects/SwiftIOS/ClassWiz/ClassWiz"
$dst = "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift/ClassWiz"
$files = @(
  "Views/Admin/AdminDashboardView.swift",
  "Views/Admin/AdminTabView.swift",
  "Views/Admin/BatchManagementView.swift",
  "Views/Admin/CourseManagementView.swift",
  "Views/Admin/PendingApprovalsView.swift",
  "Views/Admin/RoutineManagementView.swift",
  "Views/Admin/TeacherAssignmentManagementView.swift",
  "Views/Admin/UserManagementView.swift"
)

foreach($f in $files){
  Copy-Item -Path (Join-Path $src $f) -Destination (Join-Path $dst $f) -Force
}

git add ClassWiz/Views/Admin/*.swift
git diff --staged --name-only
git commit -m "sync: admin module updates"
git push -u origin sync/sarwad-admin
```

## Ready Commands: Sarwad Remaining

```powershell
Set-Location "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift"
git checkout main
git pull origin main
git checkout -b sync/sarwad-remaining

$src = "G:/KUET/Projects/SwiftIOS/ClassWiz/ClassWiz"
$dst = "G:/KUET/Projects/SwiftIOS/ClassWiz-Swift/ClassWiz"
$files = @(
  ".gitignore",
  "Assets.xcassets/AccentColor.colorset/Contents.json",
  "Assets.xcassets/AppIcon.appiconset/Contents.json",
  "Assets.xcassets/Contents.json",
  "ClassWiz.xcodeproj/project.pbxproj",
  "ClassWiz.xcodeproj/project.xcworkspace/contents.xcworkspacedata",
  "ClassWiz.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
  "ClassWiz.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings",
  "ClassWizApp.swift",
  "ContentView.swift",
  "Core/RootRouter.swift",
  "Docs/screen-cods.txt",
  "GoogleService-Info.plist",
  "Models/AttendanceRecord.swift",
  "Models/Batch.swift",
  "Models/Course.swift",
  "Models/CWNotification.swift",
  "Models/Routine.swift",
  "PreviewData/MockData.swift",
  "Resources/Theme.swift",
  "Services/AttendanceService.swift",
  "Services/BatchService.swift",
  "Services/CloudinaryService.swift",
  "Services/CourseService.swift",
  "Services/NotificationService.swift",
  "Services/RoutineService.swift",
  "Services/UserService.swift",
  "test.swift",
  "test_cloudinary.swift",
  "Utilities/ClassWizError.swift",
  "Utilities/DateFormatters.swift",
  "Utilities/HapticManager.swift",
  "Utilities/NetworkMonitor.swift",
  "ViewModels/AuthViewModel.swift",
  "ViewModels/StudentAttendanceViewModel.swift",
  "ViewModels/StudentRoutineViewModel.swift",
  "Views/Auth/AuthGateView.swift",
  "Views/Auth/LoginView.swift",
  "Views/Auth/PendingApprovalView.swift",
  "Views/Shared/CircularProgressView.swift",
  "Views/Shared/ClassWizScreen.swift",
  "Views/Shared/CWSearchBar.swift",
  "Views/Shared/EmptyStateView.swift",
  "Views/Shared/LoadingView.swift",
  "Views/Shared/NotificationView.swift",
  "Views/Shared/OfflineBanner.swift",
  "Views/Shared/ProfileView.swift",
  "Views/Shared/RiskBadge.swift",
  "Views/Shared/SyncStatusBar.swift",
  "Views/Shared/TopRoundedRectangle.swift",
  "Views/Student/LeaderboardView.swift",
  "Views/Student/StudentAssignmentsView.swift",
  "Views/Student/StudentAttendanceView.swift",
  "Views/Student/StudentCoursesAndClassesView.swift",
  "Views/Student/StudentRoutineView.swift",
  "Views/Student/StudentTabView.swift",
  "Views/Student/WhatIfSimulatorView.swift"
)

foreach($f in $files){
  Copy-Item -Path (Join-Path $src $f) -Destination (Join-Path $dst $f) -Force
}

git add ClassWiz/.gitignore ClassWiz/Assets.xcassets ClassWiz/ClassWiz.xcodeproj ClassWiz/ClassWizApp.swift ClassWiz/ContentView.swift ClassWiz/Core/RootRouter.swift ClassWiz/Docs/screen-cods.txt ClassWiz/GoogleService-Info.plist ClassWiz/Models ClassWiz/PreviewData/MockData.swift ClassWiz/Resources/Theme.swift ClassWiz/Services/AttendanceService.swift ClassWiz/Services/BatchService.swift ClassWiz/Services/CloudinaryService.swift ClassWiz/Services/CourseService.swift ClassWiz/Services/NotificationService.swift ClassWiz/Services/RoutineService.swift ClassWiz/Services/UserService.swift ClassWiz/test.swift ClassWiz/test_cloudinary.swift ClassWiz/Utilities ClassWiz/ViewModels ClassWiz/Views/Auth ClassWiz/Views/Shared ClassWiz/Views/Student
git restore --staged ClassWiz/.env
git diff --staged --name-only
git commit -m "sync: remaining updates after teacher/admin split"
git push -u origin sync/sarwad-remaining
```

## Merge Order (Recommended)

1. Maruf PR (teacher only)
2. Sarwad PR (admin only)
3. Sarwad PR (remaining files)

This order minimizes overlap for routing and shared UI files.

## Safety Rules

- Never commit `.env`.
- Commit `GoogleService-Info.plist` only if your repository policy allows it.
- Keep each PR focused on assigned scope.
- Before final merge, sync with latest main:
  - `git fetch origin`
  - `git rebase origin/main`
