> _Last updated: April 8, 2026. Verified against actual project implementation._

# 📱 FRONTEND PRD — ClassWiz

## Intelligent Class Routine & Attendance Management System

**Platform:** iOS (Target: iOS 16+)  
**Framework:** SwiftUI  
**Architecture:** MVVM (Model-View-ViewModel)  
**Design Language:** Modern, Elegant, Accessible

---

## 1. Frontend Overview

### Vision

ClassWiz delivers a **modern, elegant, and highly functional** iOS experience that transforms complex academic data into beautiful, actionable interfaces. The frontend prioritizes:

- **Visual Clarity** — Information hierarchy that guides the eye
- **Fluid Interactions** — Smooth animations and delightful micro-interactions
- **Role Adaptation** — Dynamic UI based on user role (Student/Teacher/Admin)
- **Offline Grace** — Seamless experience regardless of connectivity
- **Accessibility First** — WCAG 2.1 AA compliance for all users

### Core Principles

1. **iOS 16 Compatibility** — All features must work flawlessly on iOS 16 devices
2. **SwiftUI Native** — Leverage SwiftUI's declarative paradigm fully
3. **Performance** — 60fps animations, lazy loading, efficient memory use
4. **Consistency** — Unified design language across all screens
5. **Delight** — Thoughtful animations and feedback at every interaction

---

## 2. iOS 16 Compatibility Requirements

### Critical Constraints

| Feature | iOS 16 Support Strategy |
|---------|------------------------|
| Navigation | Use `NavigationStack` (not NavigationView) |
| Charts | Use Swift Charts framework (iOS 16+) |
| Layout | Leverage Grid and adaptive layouts |
| Async | Use Swift Concurrency (async/await) |
| Forms | Native Form with proper styling |
| Sheets | `.sheet()` and `.fullScreenCover()` modifiers |

### Avoided iOS 17+ Features

- ❌ `#Preview` macro (use `struct_Previews: PreviewProvider`)
- ❌ Observable macro (use `@StateObject` + `ObservableObject`)
- ❌ SwiftData (use Firestore SDK)
- ❌ TipKit (custom onboarding)

### Testing Requirements

- **Primary device:** iOS 16.0+ physical device
- **Simulator:** Test on iPhone 14 Pro (iOS 16.0)
- **Compatibility check:** Xcode deployment target set to iOS 16.0

---

## 3. Design System

### 3.1 Color Palette

#### Primary Colors

```swift
// Semantic Colors
struct AppColors {
    // Brand
    static let primary = Color("PrimaryBlue")      // #3B82F6
    static let primaryDark = Color("PrimaryDark")  // #1E40AF
    static let accent = Color("AccentPurple")      // #8B5CF6
    
    // Risk Status
    static let safe = Color("SafeGreen")           // #10B981
    static let warning = Color("WarningYellow")    // #F59E0B
    static let critical = Color("CriticalRed")     // #EF4444
    
    // Neutrals
    static let background = Color("Background")    // Dynamic (White/Black)
    static let surface = Color("Surface")          // Dynamic (Gray 50/900)
    static let textPrimary = Color("TextPrimary")  // Dynamic
    static let textSecondary = Color("TextSecondary") // Dynamic
    
    // Functional
    static let success = Color.green
    static let error = Color.red
    static let info = Color.blue
}
```

#### Dark Mode Strategy

- **Automatic adaptation** via `.colorScheme` environment
- **Dynamic colors** defined in Assets.xcassets
- **Contrast ratios** validated for WCAG AA (4.5:1 for text)

### 3.2 Typography

```swift
struct AppTypography {
    // Display
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Headings
    static let heading1 = Font.system(size: 24, weight: .semibold)
    static let heading2 = Font.system(size: 20, weight: .semibold)
    static let heading3 = Font.system(size: 18, weight: .medium)
    
    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let body = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    // Special
    static let caption = Font.system(size: 12, weight: .medium)
    static let label = Font.system(size: 14, weight: .medium)
    static let mono = Font.system(size: 15, design: .monospaced)
}
```

### 3.3 Spacing System

```swift
struct Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### 3.4 Corner Radius & Shadows

```swift
struct AppStyling {
    // Radius
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 24
    
    // Shadows
    static let shadowLight = Shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    static let shadowMedium = Shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    static let shadowHeavy = Shadow(color: .black.opacity(0.15), radius: 16, y: 8)
}
```

---

## 4. Architecture — MVVM Implementation

### 4.1 Layered Architecture

```
┌─────────────────────────────────────┐
│         SwiftUI Views               │ ← User Interface
├─────────────────────────────────────┤
│         ViewModels                  │ ← Business Logic & State
├─────────────────────────────────────┤
│         Services                    │ ← Firebase SDK Wrappers
├─────────────────────────────────────┤
│         Models                      │ ← Data Structures
├─────────────────────────────────────┤
│         Firebase SDK                │ ← Backend Communication
└─────────────────────────────────────┘
```

### 4.2 MVVM Pattern (iOS 16 Compatible)

#### Model
```swift
struct Attendance: Identifiable, Codable {
    let id: String
    let studentId: String
    let courseId: String
    let date: Date
    let status: AttendanceStatus
    let markedBy: String
}

enum AttendanceStatus: String, Codable {
    case present
    case absent
}
```

#### ViewModel
```swift
@MainActor
class AttendanceViewModel: ObservableObject {
    @Published var attendanceRecords: [Attendance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: AttendanceService
    
    init(service: AttendanceService = .shared) {
        self.service = service
    }
    
    func fetchAttendance(for courseId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            attendanceRecords = try await service.fetchAttendance(courseId: courseId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

#### View
```swift
struct AttendanceView: View {
    @StateObject private var viewModel = AttendanceViewModel()
    let courseId: String
    
    var body: some View {
        List(viewModel.attendanceRecords) { record in
            AttendanceRowView(record: record)
        }
        .task {
            await viewModel.fetchAttendance(for: courseId)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### 4.3 Dependency Injection Pattern

```swift
// Environment key for injecting services
struct FirebaseServiceKey: EnvironmentKey {
    static let defaultValue: FirebaseService = .shared
}

extension EnvironmentValues {
    var firebaseService: FirebaseService {
        get { self[FirebaseServiceKey.self] }
        set { self[FirebaseServiceKey.self] = newValue }
    }
}

// Usage in views
struct ContentView: View {
    @Environment(\.firebaseService) var firebaseService
    // ...
}
```

---

## 5. Navigation Architecture

### 5.1 Navigation Structure (iOS 16)

```swift
// Root navigation using NavigationStack
struct AppRootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            if authService.isAuthenticated {
                RoleBasedHomeView(role: authService.userRole)
            } else {
                LoginView()
            }
        }
    }
}
```

### 5.2 Role-Based Navigation

```swift
struct RoleBasedHomeView: View {
    let role: UserRole
    
    var body: some View {
        switch role {
        case .student:
            StudentTabView()
        case .teacher:
            TeacherTabView()
        case .admin:
            AdminTabView()
        }
    }
}
```

### 5.3 Tab Navigation Per Role

#### Student Tabs
```swift
struct StudentTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            RoutineView()
                .tabItem {
                    Label("Routine", systemImage: "calendar")
                }
            
            AttendanceView()
                .tabItem {
                    Label("Attendance", systemImage: "checkmark.circle.fill")
                }
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "chart.bar.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(AppColors.primary)
    }
}
```

#### Teacher Tabs
```swift
struct TeacherTabView: View {
    var body: some View {
        TabView {
            TeacherDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            MyCoursesView()
                .tabItem {
                    Label("My Courses", systemImage: "book.fill")
                }
            
            MarkAttendanceView()
                .tabItem {
                    Label("Mark Attendance", systemImage: "checkmark.square.fill")
                }
            
            TeacherProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
```

#### Admin Tabs
```swift
struct AdminTabView: View {
    var body: some View {
        TabView {
            AdminDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            ManageCoursesView()
                .tabItem {
                    Label("Courses", systemImage: "book.closed.fill")
                }
            
            ManageRoutinesView()
                .tabItem {
                    Label("Routines", systemImage: "calendar.badge.clock")
                }
            
            ManageUsersView()
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
        }
    }
}
```

---

## 6. Screen Specifications — Student Role

### 6.1 Student Dashboard

**Purpose:** At-a-glance overview of academic status

**Layout:**
```
┌─────────────────────────────────┐
│  Welcome, [Name]               │ ← Greeting header
│  [Today's Date]                │
├─────────────────────────────────┤
│  📊 Overall Attendance          │
│  [Circular Progress: 82%]      │ ← Large animated gauge
│  🟢 Safe Zone                   │
├─────────────────────────────────┤
│  📅 Today's Classes             │
│  ┌───────────────────────────┐ │
│  │ CSE-321  09:00 - 10:30   │ │ ← Card list
│  │ Room 301 • Dr. Ahmed     │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ CSE-322  11:00 - 12:30   │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  ⚠️ Alerts                      │
│  • CSE-323: Warning Zone (77%) │ ← Risk alerts
│  • Attend next 2 classes       │
├─────────────────────────────────┤
│  🏆 Leaderboard Rank: #12/45   │ ← Quick leaderboard peek
└─────────────────────────────────┘
```

**Components:**
- `WelcomeHeader` — Personalized greeting with avatar
- `AttendanceGauge` — Circular progress with risk badge
- `TodayClassCard` — Compact class info card
- `AlertBanner` — Dismissible warning/critical alerts
- `QuickStatCard` — Leaderboard rank preview

**Interactions:**
- Pull-to-refresh for sync
- Tap class card → navigate to course detail
- Tap attendance gauge → navigate to attendance view
- Tap alert → navigate to affected course

**Animations:**
- Gauge animates on appear (spring animation, 0.8s)
- Cards stagger in (cascade delay: 0.1s each)
- Alert banner slides in from top

---

### 6.2 Attendance View (Student)

**Purpose:** Detailed course-wise attendance tracking

**Layout:**
```
┌─────────────────────────────────┐
│  Attendance                     │ ← Navigation title
│  [Semester Picker]              │ ← Semester filter
├─────────────────────────────────┤
│  CSE-321: Database Systems      │
│  ┌───────────────────────────┐ │
│  │ 🟢 82%  [Progress Bar]    │ │
│  │ 32/39 classes attended    │ │
│  │ → View Details            │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  CSE-322: Software Engineering  │
│  ┌───────────────────────────┐ │
│  │ 🟡 77%  [Progress Bar]    │ │
│  │ 30/39 classes attended    │ │
│  │ ⚠️ Attend next 2 classes  │ │
│  │ → View Details            │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  CSE-323: Computer Networks     │
│  ┌───────────────────────────┐ │
│  │ 🔴 68%  [Progress Bar]    │ │
│  │ 26/38 classes attended    │ │
│  │ ⚠️ Need 7 consecutive!   │ │
│  │ → View Details            │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

**Components:**
- `SemesterPicker` — Dropdown/segmented control
- `CourseAttendanceCard` — Expandable card with progress
- `RiskBadge` — Color-coded status indicator
- `RecoveryHint` — Smart suggestion text

**Detail View (Tap "View Details"):**
```
┌─────────────────────────────────┐
│  ← CSE-321: Database Systems    │
├─────────────────────────────────┤
│  📊 Statistics                  │
│  • Attended: 32                 │
│  • Total: 39                    │
│  • Percentage: 82%              │
│  • Status: 🟢 Safe              │
├─────────────────────────────────┤
│  📈 Trend Chart                 │
│  [Line chart: last 8 weeks]    │ ← Swift Charts
├─────────────────────────────────┤
│  🎯 What-If Simulator           │
│  [Slider: Future absences]     │
│  → Predicted: 78% (🟡 Warning) │
├─────────────────────────────────┤
│  📅 History                     │
│  Feb 25 • ✅ Present           │
│  Feb 22 • ❌ Absent            │
│  Feb 20 • ✅ Present           │
│  ...                            │
└─────────────────────────────────┘
```

**Interactions:**
- Swipe to refresh attendance data
- Tap card → expand to detail view
- Drag slider → update "What-If" prediction in real-time
- Tap history item → show date details

**Animations:**
- Progress bars animate on appear (linear, 1s)
- Risk badge pulses if critical status
- Chart animates data points sequentially

---

### 6.3 Routine View (Student)

**Purpose:** Weekly class schedule visualization

**Layout:**
```
┌─────────────────────────────────┐
│  Class Routine                  │
│  [Week Picker: ◀ Week 8 ▶]     │
├─────────────────────────────────┤
│  Monday                         │
│  ┌───────────────────────────┐ │
│  │ 09:00 - 10:30             │ │
│  │ CSE-321 • Room 301        │ │
│  │ Dr. Ahmed                 │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ 11:00 - 12:30             │ │
│  │ CSE-322 • Room 205        │ │
│  │ Prof. Sarah               │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  Tuesday                        │
│  ┌───────────────────────────┐ │
│  │ 10:00 - 11:30             │ │
│  │ CSE-323 • Lab 2           │ │
│  │ Dr. John                  │ │
│  └───────────────────────────┘ │
│  ...                            │
└─────────────────────────────────┘
```

**Alternative View: Grid Calendar**
```
┌─────────────────────────────────┐
│  [List View] [Grid View] ←─────┤ ← Toggle
├─────────────────────────────────┤
│    Mon   Tue   Wed   Thu   Fri  │
│ 09 [321] [--]  [321] [--]  [--] │
│ 10 [--]  [323] [--]  [322] [--] │
│ 11 [322] [--]  [--]  [--]  [321]│
│ ...                             │
└─────────────────────────────────┘
```

**Components:**
- `WeekPicker` — Horizontal date picker
- `RoutineCard` — Time, course, room, instructor
- `DaySection` — Grouped list section
- `GridTimeSlot` — Compact grid cell

**Interactions:**
- Swipe between weeks
- Tap card → show course details + attendance
- Toggle list/grid view
- Long press → add to calendar (iOS Calendar integration)

**Animations:**
- Cards fade in per day (stagger: 0.05s)
- Week transition slides horizontally
- Current time indicator animates position

---

### 6.4 Leaderboard View (Student)

**Purpose:** Gamified peer comparison with privacy

**Layout:**
```
┌─────────────────────────────────┐
│  🏆 Leaderboard                 │
│  [Course Filter ▼]              │
├─────────────────────────────────┤
│  Your Rank: #12 / 45            │
│  ┌───────────────────────────┐ │
│  │ You • 82%                 │ │ ← Highlighted row
│  │ [Progress bar]            │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  Top Students                   │
│  🥇 #1  Sarah Khan     •  98%  │
│  🥈 #2  Ahmed Ali      •  96%  │
│  🥉 #3  Fatima Hassan  •  94%  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  #4   John Doe        •  92%  │
│  #5   Jane Smith      •  90%  │
│  ...                            │
│  #11  Anonymous       •  83%  │
│  YOU  #12             •  82%  │ ← Context
│  #13  Anonymous       •  81%  │
│  ...                            │
└─────────────────────────────────┘
```

**Privacy Controls:**
```
┌─────────────────────────────────┐
│  ⚙️ Leaderboard Settings        │
├─────────────────────────────────┤
│  Show my name    [Toggle: ON]  │
│  Show my rank    [Toggle: ON]  │
│  Show near me    [Toggle: ON]  │
└─────────────────────────────────┘
```

**Components:**
- `CourseFilter` — Dropdown menu
- `RankCard` — User's position highlight
- `LeaderboardRow` — Rank, name/anon, percentage
- `MedalBadge` — Top 3 special icons

**Interactions:**
- Filter by course
- Pull to refresh rankings
- Tap row → view public profile (if enabled)
- Settings button → privacy controls

**Animations:**
- Medals shimmer on appear
- User row pulses subtly
- New rank animates with confetti (if improved)

---

### 6.5 What-If Simulator (Student)

**Purpose:** Interactive attendance prediction tool

**Layout:**
```
┌─────────────────────────────────┐
│  🎯 Attendance Simulator        │
│  Course: CSE-321                │
├─────────────────────────────────┤
│  Current Status                 │
│  • Attended: 32 / 39            │
│  • Percentage: 82%              │
│  • Status: 🟢 Safe              │
├─────────────────────────────────┤
│  Simulate Future                │
│  Future absences: [Slider: 3]  │
│  Remaining classes: [Input: 10]│
├─────────────────────────────────┤
│  📊 Prediction                  │
│  ┌───────────────────────────┐ │
│  │ Final Attendance           │ │
│  │ 32 / 49 = 65%             │ │
│  │ 🔴 CRITICAL                │ │ ← Dynamic color
│  │                            │ │
│  │ ⚠️ You will be ineligible! │ │
│  │ Recommendation:            │ │
│  │ Attend at least 8/10       │ │
│  │ remaining classes          │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  📈 Visual Forecast             │
│  [Chart showing trajectory]    │ ← Swift Charts
└─────────────────────────────────┘
```

**Components:**
- `StatusCard` — Current state summary
- `SimulatorControls` — Slider + stepper
- `PredictionCard` — Calculated result with risk badge
- `RecommendationText` — Smart suggestion
- `ForecastChart` — Line chart with threshold markers

**Interactions:**
- Drag slider → instant recalculation
- Input field for precise numbers
- Tap recommendation → see detailed recovery plan
- Share button → export prediction as image

**Animations:**
- Prediction card animates scale + color change
- Chart path draws smoothly (0.6s curve)
- Risk badge transitions color fluidly

---

## 7. Screen Specifications — Teacher Role

### 7.1 Teacher Dashboard

**Purpose:** Overview of teaching schedule and quick actions

**Layout:**
```
┌─────────────────────────────────┐
│  Welcome, Dr. Ahmed            │
│  [Today's Date]                │
├─────────────────────────────────┤
│  📚 My Courses                  │
│  • CSE-321 (2 sections)        │
│  • CSE-401 (1 section)         │
├─────────────────────────────────┤
│  📅 Today's Classes             │
│  ┌───────────────────────────┐ │
│  │ CSE-321 • Batch 3A        │ │
│  │ 09:00 - 10:30 • Room 301  │ │
│  │ [Mark Attendance]         │ │ ← CTA button
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ CSE-401 • Batch 4B        │ │
│  │ 14:00 - 15:30 • Lab 2     │ │
│  │ [Mark Attendance]         │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  📊 Quick Stats                 │
│  • Students: 120               │
│  • Avg Attendance: 78%         │
│  • At Risk: 15 students        │
└─────────────────────────────────┘
```

**Components:**
- `TeacherHeader` — Greeting + avatar
- `CourseList` — Assigned courses summary
- `UpcomingClassCard` — Class with CTA
- `QuickStatsGrid` — 2x2 metric cards

**Interactions:**
- Tap course → view course analytics
- Tap "Mark Attendance" → attendance marking flow
- Pull to refresh schedule

**Animations:**
- Class cards pulse 15 minutes before start time
- Quick stats counter animates on appear

---

### 7.2 Mark Attendance View (Teacher)

**Purpose:** Efficient bulk attendance marking

**Layout:**
```
┌─────────────────────────────────┐
│  ← Mark Attendance              │
│  CSE-321 • Batch 3A             │
│  Feb 28, 2026 • 09:00-10:30     │
├─────────────────────────────────┤
│  [Search students...]           │
├─────────────────────────────────┤
│  Quick Actions:                 │
│  [Mark All Present] [Mark All Absent]│
├─────────────────────────────────┤
│  Roll  Name           Status    │
│  ────────────────────────────── │
│  001   Sarah Khan     [✓]  [ ]  │ ← Toggle buttons
│  002   Ahmed Ali      [✓]  [ ]  │
│  003   Fatima Hassan  [ ]  [✗]  │
│  004   John Doe       [✓]  [ ]  │
│  ...                            │
├─────────────────────────────────┤
│  Summary: 38/40 Present (95%)   │
│  [Save Attendance]              │ ← Primary CTA
└─────────────────────────────────┘
```

**Quick Mark Flow (Alternative):**
```
┌─────────────────────────────────┐
│  Swipe Mode                     │
│  Swipe right = Present ✓        │
│  Swipe left = Absent ✗          │
├─────────────────────────────────┤
│  ┌───────────────────────────┐ │
│  │ 001 • Sarah Khan          │ │ ← Swipeable card
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ 002 • Ahmed Ali           │ │
│  └───────────────────────────┘ │
│  ...                            │
└─────────────────────────────────┘
```

**Components:**
- `ClassHeader` — Course + batch + date context
- `SearchBar` — Filter students by name/roll
- `QuickActionBar` — Bulk operations
- `AttendanceRow` — Student with toggle/swipe
- `SummaryBar` — Live count + save button

**Interactions:**
- Toggle present/absent
- Swipe right/left for quick mark
- Search to filter list
- Bulk select with "Mark All"
- Confirm before save (if < 60% present)

**Animations:**
- Swipe reveals colored background (green/red)
- Row shake animation on toggle
- Save button pulses when unsaved changes exist

**Validation:**
- Prevent save if edit window expired (configurable: 24 hours)
- Show warning if attendance rate is unusually low
- Require confirmation for bulk operations

---

### 7.3 Course Analytics (Teacher)

**Purpose:** Deep insights into course performance

**Layout:**
```
┌─────────────────────────────────┐
│  ← CSE-321: Database Systems    │
│  Batch 3A                       │
├─────────────────────────────────┤
│  📊 Overview                    │
│  • Total Students: 40           │
│  • Avg Attendance: 78%          │
│  • Classes Held: 39             │
├─────────────────────────────────┤
│  📈 Attendance Trend            │
│  [Line chart: last 10 weeks]   │ ← Swift Charts
├─────────────────────────────────┤
│  🚨 At-Risk Students (12)       │
│  🔴 Critical (<75%)             │
│  • John Doe: 68%                │
│  • Jane Smith: 72%              │
│  🟡 Warning (75-79%)            │
│  • Alex Brown: 77%              │
│  ...                            │
├─────────────────────────────────┤
│  📅 Recent Classes              │
│  Feb 25 • 38/40 present (95%)   │
│  Feb 22 • 35/40 present (87%)   │
│  ...                            │
└─────────────────────────────────┘
```

**Components:**
- `CourseHeader` — Course + batch info
- `StatsOverview` — Key metrics grid
- `TrendChart` — Multi-week line chart
- `RiskStudentsList` — Grouped by severity
- `RecentClassesList` — Chronological log

**Interactions:**
- Tap at-risk student → view individual detail
- Tap recent class → edit attendance (if within window)
- Export report → share as PDF

**Animations:**
- Charts animate on appear
- At-risk list items slide in with color-coded indicators

---

## 8. Screen Specifications — Admin Role

### 8.1 Admin Dashboard

**Purpose:** System-wide overview and quick access to management tools

**Layout:**
```
┌─────────────────────────────────┐
│  Admin Dashboard               │
├─────────────────────────────────┤
│  📊 System Stats                │
│  ┌──────────┬──────────┐       │
│  │ Students │ Teachers │       │
│  │   245    │    18    │       │
│  ├──────────┼──────────┤       │
│  │ Courses  │ Batches  │       │
│  │    42    │    8     │       │
│  └──────────┴──────────┘       │
├─────────────────────────────────┤
│  🔧 Quick Actions               │
│  [+ Add Course]                 │
│  [+ Add User]                   │
│  [📅 Manage Routines]           │
│  [👥 Assign Teachers]           │
├─────────────────────────────────┤
│  ⚠️ System Alerts               │
│  • 3 courses without teachers   │
│  • 2 routine conflicts          │
└─────────────────────────────────┘
```

**Components:**
- `StatsGrid` — 2x2 system metrics
- `QuickActionGrid` — Large tappable cards
- `AlertsList` — System warnings requiring attention

---

### 8.2 Manage Courses (Admin)

**Purpose:** CRUD operations for courses

**Layout:**
```
┌─────────────────────────────────┐
│  Courses                 [+ Add]│
│  [Search courses...]            │
├─────────────────────────────────┤
│  Active Courses (38)            │
│  ┌───────────────────────────┐ │
│  │ CSE-321                   │ │
│  │ Database Systems          │ │
│  │ Credit: 3 • Active        │ │
│  │ [Edit] [Archive]          │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ CSE-322                   │ │
│  │ Software Engineering      │ │
│  │ Credit: 3 • Active        │ │
│  │ [Edit] [Archive]          │ │
│  └───────────────────────────┘ │
│  ...                            │
├─────────────────────────────────┤
│  Archived Courses (4)           │
│  [Expand ▼]                     │
└─────────────────────────────────┘
```

**Add/Edit Form:**
```
┌─────────────────────────────────┐
│  ← Add Course                   │
├─────────────────────────────────┤
│  Course Code                    │
│  [CSE-421    ]                  │
│                                 │
│  Course Name                    │
│  [Machine Learning  ]           │
│                                 │
│  Credit Hours                   │
│  [3  ]                          │
│                                 │
│  Status                         │
│  [ ] Active                     │
│                                 │
│  [Save Course]                  │
└─────────────────────────────────┘
```

**Components:**
- `CourseCard` — Course info with action buttons
- `CourseForm` — SwiftUI Form with validation
- `ArchiveButton` — Soft delete with confirmation

**Interactions:**
- Search/filter courses
- Tap card → expand details
- Edit → pre-fill form
- Archive → confirmation alert
- Validation: unique course code, required fields

---

### 8.3 Manage Routines (Admin)

**Purpose:** Schedule management with conflict detection

**Layout:**
```
┌─────────────────────────────────┐
│  Routines              [+ Add]  │
│  [Batch Filter ▼]               │
├─────────────────────────────────┤
│  Monday                         │
│  ┌───────────────────────────┐ │
│  │ 09:00 - 10:30             │ │
│  │ CSE-321 • Batch 3A        │ │
│  │ Room 301 • Dr. Ahmed      │ │
│  │ [Edit] [Delete]           │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ 11:00 - 12:30             │ │
│  │ CSE-322 • Batch 3A        │ │
│  │ ⚠️ Conflict: Room overlap  │ │ ← Validation warning
│  │ [Edit] [Delete]           │ │
│  └───────────────────────────┘ │
│  ...                            │
└─────────────────────────────────┘
```

**Add Routine Form:**
```
┌─────────────────────────────────┐
│  ← Add Routine                  │
├─────────────────────────────────┤
│  Course                         │
│  [Select Course ▼]              │
│                                 │
│  Batch                          │
│  [Select Batch ▼]               │
│                                 │
│  Teacher                        │
│  [Select Teacher ▼]             │
│                                 │
│  Day                            │
│  [Monday ▼]                     │
│                                 │
│  Time Slot                      │
│  From: [09:00]  To: [10:30]    │
│                                 │
│  Room                           │
│  [301  ]                        │
│                                 │
│  [Check Conflicts]              │
│  [Save Routine]                 │
└─────────────────────────────────┘
```

**Conflict Detection:**
```
⚠️ Conflicts Found:
• Dr. Ahmed has another class at this time
• Room 301 is already booked
• Batch 3A has overlapping schedule

[Adjust Time] [Change Room] [Cancel]
```

**Components:**
- `RoutineCard` — Schedule entry with metadata
- `RoutineForm` — Multi-picker form
- `ConflictAlert` — Validation results sheet
- `TimePicker` — Custom time selection

**Interactions:**
- Filter by batch/day
- Drag to reorder (future enhancement)
- Real-time conflict check before save
- Delete with confirmation

---

### 8.4 Assign Teachers (Admin)

**Purpose:** Link teachers to courses and batches

**Layout:**
```
┌─────────────────────────────────┐
│  Teacher Assignments    [+ Add] │
│  [Teacher Filter ▼]             │
├─────────────────────────────────┤
│  Dr. Ahmed                      │
│  ┌───────────────────────────┐ │
│  │ CSE-321 • Batch 3A        │ │
│  │ CSE-321 • Batch 3B        │ │
│  │ CSE-401 • Batch 4A        │ │
│  │ [Edit] [Remove]           │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  Prof. Sarah                    │
│  ┌───────────────────────────┐ │
│  │ CSE-322 • Batch 3A        │ │
│  │ [Edit] [Remove]           │ │
│  └───────────────────────────┘ │
│  ...                            │
└─────────────────────────────────┘
```

**Assignment Form:**
```
┌─────────────────────────────────┐
│  ← Assign Teacher               │
├─────────────────────────────────┤
│  Teacher                        │
│  [Select Teacher ▼]             │
│  → Dr. Ahmed                    │
│                                 │
│  Course                         │
│  [Select Course ▼]              │
│  → CSE-421: Machine Learning    │
│                                 │
│  Batches (Multi-select)         │
│  [✓] Batch 3A                   │
│  [ ] Batch 3B                   │
│  [✓] Batch 4A                   │
│                                 │
│  [Save Assignment]              │
└─────────────────────────────────┘
```

**Components:**
- `TeacherSection` — Grouped assignments per teacher
- `AssignmentCard` — Course + batch pair
- `AssignmentForm` — Multi-picker with validation

**Interactions:**
- Filter by teacher
- Multi-select batches
- Validation: no duplicate assignments
- Remove with confirmation

---

## 9. Reusable Component Library

### 9.1 Cards

#### `GlassCard`
```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(AppStyling.radiusMedium)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
```

#### `StatCard`
```swift
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(AppTypography.displayMedium)
                .fontWeight(.bold)
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(AppStyling.radiusMedium)
    }
}
```

---

### 9.2 Badges & Indicators

#### `RiskBadge`
```swift
struct RiskBadge: View {
    let percentage: Double
    
    var riskLevel: RiskLevel {
        switch percentage {
        case 80...: return .safe
        case 75..<80: return .warning
        default: return .critical
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(riskLevel.color)
                .frame(width: 8, height: 8)
            Text(riskLevel.text)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(riskLevel.color.opacity(0.15))
        .cornerRadius(12)
    }
}

enum RiskLevel {
    case safe, warning, critical
    
    var color: Color {
        switch self {
        case .safe: return AppColors.safe
        case .warning: return AppColors.warning
        case .critical: return AppColors.critical
        }
    }
    
    var text: String {
        switch self {
        case .safe: return "Safe"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}
```

#### `SyncStatusIndicator`
```swift
struct SyncStatusIndicator: View {
    @Binding var lastSynced: Date?
    @Binding var isSyncing: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
            } else if let lastSynced = lastSynced {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Synced \(lastSynced.relativeTime)")
            } else {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                Text("Offline")
            }
        }
        .font(AppTypography.caption)
        .foregroundColor(.secondary)
    }
}
```

---

### 9.3 Progress Indicators

#### `CircularProgressView`
```swift
struct CircularProgressView: View {
    let percentage: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(
                    colorForPercentage(percentage),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8), value: percentage)
            
            if showLabel {
                VStack(spacing: 4) {
                    Text("\(Int(percentage))%")
                        .font(AppTypography.displayMedium)
                        .fontWeight(.bold)
                    RiskBadge(percentage: percentage)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    func colorForPercentage(_ pct: Double) -> Color {
        switch pct {
        case 80...: return AppColors.safe
        case 75..<80: return AppColors.warning
        default: return AppColors.critical
        }
    }
}
```

#### `LinearProgressBar`
```swift
struct LinearProgressBar: View {
    let percentage: Double
    let height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [colorForPercentage(percentage), colorForPercentage(percentage).opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (percentage / 100))
                    .animation(.spring(response: 1.0), value: percentage)
            }
        }
        .frame(height: height)
    }
    
    func colorForPercentage(_ pct: Double) -> Color {
        switch pct {
        case 80...: return AppColors.safe
        case 75..<80: return AppColors.warning
        default: return AppColors.critical
        }
    }
}
```

---

### 9.4 Empty States

#### `EmptyStateView`
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(AppTypography.heading2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.label)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(AppStyling.radiusMedium)
                }
            }
        }
        .padding()
    }
}
```

---

### 9.5 Loading States

#### `LoadingOverlay`
```swift
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.white)
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .cornerRadius(AppStyling.radiusMedium)
        }
    }
}
```

---

### 9.6 Form Components

#### `FloatingLabelTextField`
```swift
struct FloatingLabelTextField: View {
    let label: String
    @Binding var text: String
    let icon: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isFocused || !text.isEmpty {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                }
                
                TextField(isFocused ? "" : label, text: $text)
                    .focused($isFocused)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(AppStyling.radiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyling.radiusSmall)
                    .stroke(isFocused ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .animation(.spring(response: 0.3), value: isFocused)
    }
}
```

---

## 10. Animations & Micro-interactions

### 10.1 Animation Principles

1. **Spring Physics** — Natural, organic motion
2. **Easing** — Ease-out for entrances, ease-in for exits
3. **Duration** — 0.3s for micro, 0.6s for transitions
4. **Stagger** — 0.05-0.1s delay for list items
5. **Purpose** — Every animation serves feedback or hierarchy

### 10.2 Standard Animations

#### Page Transitions
```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
```

#### Card Appear
```swift
.onAppear {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(index * 0.1)) {
        opacity = 1
        scale = 1
    }
}
```

#### Button Press
```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
```

#### Shake (Error Feedback)
```swift
func shake() {
    withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
        offset = 10
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            offset = 0
        }
    }
}
```

#### Success Checkmark
```swift
Circle()
    .trim(from: 0, to: isSuccess ? 1 : 0)
    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .animation(.spring(response: 0.8), value: isSuccess)
```

### 10.3 Haptic Feedback

```swift
struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
```

**Usage Guidelines:**
- Button taps → `light()`
- Toggle switches → `medium()`
- Successful save → `success()`
- Validation errors → `error()`

---

## 11. Accessibility

### 11.1 VoiceOver Support

```swift
// Example: Attendance card
AttendanceCard(...)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("CSE-321 Database Systems")
    .accessibilityValue("Attendance 82 percent, Safe zone")
    .accessibilityHint("Double tap to view details")
```

### 11.2 Dynamic Type

```swift
// All text must scale with system font size
Text("Welcome")
    .font(.system(.title, design: .rounded))
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### 11.3 Color Contrast

- **Text on background:** Minimum 4.5:1 (WCAG AA)
- **Large text (≥18pt):** Minimum 3:1
- **Icons:** Minimum 3:1

### 11.4 Accessibility Modifiers Checklist

- [ ] `.accessibilityLabel()` for all interactive elements
- [ ] `.accessibilityHint()` for non-obvious actions
- [ ] `.accessibilityValue()` for dynamic content
- [ ] `.accessibilityAddTraits()` for buttons (.isButton)
- [ ] `.accessibilityIdentifier()` for UI testing
- [ ] Test with VoiceOver enabled
- [ ] Test with large text sizes
- [ ] Test with Reduce Motion enabled

---

## 12. Offline Support & Sync

### 12.1 Offline UI Patterns

#### Connection Banner
```swift
struct OfflineBanner: View {
    @Binding var isOffline: Bool
    
    var body: some View {
        if isOffline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("You're offline. Changes will sync when connected.")
                    .font(AppTypography.caption)
            }
            .padding()
            .background(Color.orange.opacity(0.2))
            .foregroundColor(.orange)
            .transition(.move(edge: .top))
        }
    }
}
```

#### Cached Data Indicator
```swift
Text("Last updated: \(lastSyncDate.formatted())")
    .font(AppTypography.caption)
    .foregroundColor(.secondary)
```

#### Disabled Actions
```swift
Button("Mark Attendance") {
    // ...
}
.disabled(isOffline)
.opacity(isOffline ? 0.5 : 1.0)
```

### 12.2 Sync Status

```swift
enum SyncStatus {
    case synced
    case syncing
    case offline
    case error(String)
    
    var icon: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .synced: return .green
        case .syncing: return .blue
        case .offline: return .orange
        case .error: return .red
        }
    }
}
```

---

## 13. Error Handling & User Feedback

### 13.1 Error Display Patterns

#### Inline Error
```swift
if let error = viewModel.errorMessage {
    HStack {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
        Text(error)
            .font(AppTypography.bodySmall)
            .foregroundColor(.red)
    }
    .padding()
    .background(Color.red.opacity(0.1))
    .cornerRadius(AppStyling.radiusSmall)
}
```

#### Alert Dialog
```swift
.alert("Error", isPresented: $showError) {
    Button("OK", role: .cancel) { }
    Button("Retry", role: .none) {
        Task { await viewModel.retry() }
    }
} message: {
    Text(viewModel.errorMessage ?? "Something went wrong")
}
```

#### Toast/Snackbar
```swift
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: type.icon)
                    Text(message)
                        .font(AppTypography.body)
                }
                .padding()
                .background(type.color)
                .foregroundColor(.white)
                .cornerRadius(AppStyling.radiusMedium)
                .shadow(radius: 10)
                .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

enum ToastType {
    case success, error, info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}
```

---

## 14. Performance Optimization

### 14.1 Lazy Loading

```swift
// Use LazyVStack/LazyHStack for long lists
ScrollView {
    LazyVStack(spacing: Spacing.md) {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}
```

### 14.2 Image Optimization

```swift
// Async image loading with caching
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
            .foregroundColor(.secondary)
    @unknown default:
        EmptyView()
    }
}
.frame(width: 60, height: 60)
.clipShape(Circle())
```

### 14.3 View Hierarchy Optimization

```swift
// Prefer @ViewBuilder for conditional views
@ViewBuilder
func statusView() -> some View {
    switch status {
    case .loading:
        ProgressView()
    case .success(let data):
        DataView(data: data)
    case .error(let message):
        ErrorView(message: message)
    }
}
```

### 14.4 Memory Management

- Use `@StateObject` for view-owned objects
- Use `@ObservedObject` for passed objects
- Use `@EnvironmentObject` for app-wide state
- Implement `deinit` for cleanup in ViewModels
- Avoid retain cycles with `[weak self]` in closures

---

## 15. Testing Strategy

### 15.1 Preview Providers (iOS 16 Compatible)

```swift
struct AttendanceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            AttendanceView()
                .preferredColorScheme(.light)
            
            // Dark mode
            AttendanceView()
                .preferredColorScheme(.dark)
            
            // Large text
            AttendanceView()
                .environment(\.dynamicTypeSize, .xxxLarge)
            
            // Empty state
            AttendanceView()
                .environmentObject(AttendanceViewModel(mockData: []))
        }
    }
}
```

### 15.2 UI Testing Identifiers

```swift
// Add identifiers to all testable elements
Button("Login") {
    // ...
}
.accessibilityIdentifier("loginButton")

TextField("Email", text: $email)
    .accessibilityIdentifier("emailField")
```

### 15.3 Test Scenarios

- [ ] Login flow (success/failure)
- [ ] Role-based navigation
- [ ] Offline mode graceful degradation
- [ ] Pull-to-refresh sync
- [ ] Form validation
- [ ] CRUD operations
- [ ] Dark mode consistency
- [ ] VoiceOver navigation
- [ ] Dynamic Type scaling

---

## 16. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Project setup with iOS 16 target
- [ ] Firebase integration
- [ ] Design system implementation (colors, typography, spacing)
- [ ] Authentication flow (login/logout)
- [ ] Role resolution and routing

### Phase 2: Student Module (Week 3-4)
- [ ] Student dashboard
- [ ] Attendance view with detail
- [ ] Routine view (list + grid)
- [ ] What-If simulator
- [ ] Leaderboard

### Phase 3: Teacher Module (Week 5)
- [ ] Teacher dashboard
- [ ] Mark attendance flow
- [ ] Course analytics

### Phase 4: Admin Module (Week 6)
- [ ] Admin dashboard
- [ ] Manage courses (CRUD)
- [ ] Manage routines with conflict detection
- [ ] Teacher assignments

### Phase 5: Polish & Testing (Week 7-8)
- [ ] Animations and micro-interactions
- [ ] Accessibility audit
- [ ] Offline mode testing
- [ ] Performance optimization
- [ ] Dark mode refinement
- [ ] User testing and feedback
- [ ] Bug fixes

---

## 17. Code Quality Standards

### 17.1 Swift Style Guide

```swift
// MARK: - Good practices

// 1. Use meaningful names
let attendancePercentage = 82.5 // ✅
let ap = 82.5 // ❌

// 2. Prefer guard for early returns
guard let user = currentUser else {
    return // ✅
}

// 3. Use MARK comments for organization
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Actions
// MARK: - Helpers

// 4. Avoid force unwrapping
if let name = user?.name { // ✅
let name = user!.name // ❌

// 5. Use trailing closures
Button("Save") {
    save()
} // ✅
```

### 17.2 File Organization

```
ClassWiz/
├── App/
│   ├── ClassWizApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Extensions/
│   ├── Utilities/
│   └── Constants/
├── Models/
│   ├── User.swift
│   ├── Course.swift
│   ├── Attendance.swift
│   └── Routine.swift
├── Services/
│   ├── AuthService.swift
│   ├── FirestoreService.swift
│   └── AttendanceService.swift
├── ViewModels/
│   ├── Student/
│   ├── Teacher/
│   └── Admin/
├── Views/
│   ├── Common/
│   │   ├── Components/
│   │   └── Modifiers/
│   ├── Student/
│   ├── Teacher/
│   └── Admin/
└── Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist
```

---

## 18. Launch Checklist

### Pre-Launch
- [ ] iOS 16 compatibility verified on physical device
- [ ] All features tested per role
- [ ] Offline mode tested
- [ ] Dark mode consistency checked
- [ ] VoiceOver navigation verified
- [ ] Large text sizes tested
- [ ] Performance profiling completed
- [ ] Memory leaks checked with Instruments
- [ ] Network conditions tested (slow 3G, offline)
- [ ] Error states handled gracefully

### Documentation
- [ ] README updated
- [ ] Code comments for complex logic
- [ ] API integration documented
- [ ] Known issues listed

### Deployment
- [ ] Build version incremented
- [ ] Deployment target set to iOS 16.0
- [ ] GoogleService-Info.plist added (not committed)
- [ ] Release build tested
- [ ] Archive created for demonstration

---

## 19. Viva Preparation — Frontend Talking Points

### Key Strengths to Highlight

1. **iOS 16 Compatibility**
   > "The entire app is built to run flawlessly on iOS 16, which is the target device for demonstration. We carefully avoided iOS 17+ APIs."

2. **MVVM Architecture**
   > "We followed MVVM pattern with clear separation: Views handle UI, ViewModels manage state and business logic, and Services wrap Firebase SDK calls."

3. **Role-Based UI**
   > "The app dynamically adapts its entire interface based on the authenticated user's role—student, teacher, or admin—showing only relevant features."

4. **Offline-First Design**
   > "We leveraged Firestore's offline persistence and built graceful degradation so the app remains usable without connectivity."

5. **Accessibility**
   > "Full VoiceOver support, Dynamic Type compatibility, and WCAG AA contrast ratios ensure the app is accessible to all users."

6. **Modern Design Language**
   > "We used SwiftUI's material effects, spring animations, and iOS Human Interface Guidelines to create an elegant, native iOS experience."

7. **Performance**
   > "Lazy loading, efficient view hierarchies, and proper state management ensure 60fps animations and smooth scrolling even with large datasets."

### Demo Flow
1. **Login** → Show role resolution
2. **Student Dashboard** → Highlight animations, risk classification
3. **Attendance Detail** → Show What-If simulator, charts
4. **Leaderboard** → Demonstrate gamification
5. **Teacher Flow** → Mark attendance, swipe gestures
6. **Admin Panel** → CRUD operations, validation
7. **Offline Mode** → Airplane mode test
8. **Dark Mode** → Toggle system appearance

---

## 20. Conclusion

This frontend PRD provides a **comprehensive blueprint** for building ClassWiz with:

✅ **Modern, elegant UI/UX** following iOS design principles  
✅ **iOS 16 compatibility** without reliance on newer APIs  
✅ **Role-based adaptive interfaces** for student/teacher/admin  
✅ **MVVM architecture** with clean separation of concerns  
✅ **Offline-first design** with graceful degradation  
✅ **Accessibility-first approach** with VoiceOver and Dynamic Type  
✅ **Reusable component library** for consistency and efficiency  
✅ **Detailed screen specifications** with layouts and interactions  
✅ **Animation and micro-interaction guidelines** for delight  
✅ **Performance optimization strategies** for smooth experience  

**The result:** A production-ready iOS application that not only meets functional requirements but delivers a delightful, accessible, and performant user experience worthy of a standout academic project.

---

**Document Version:** 1.0  
**Last Updated:** February 28, 2026  
**Target Platform:** iOS 16.0+  
**Framework:** SwiftUI  
**Status:** Ready for Implementation ✨
