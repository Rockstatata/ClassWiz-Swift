// TeacherDashboardView.swift
// ClassWiz – Views/Teacher

import SwiftUI
import Combine

struct TeacherAssignmentDisplay: Identifiable, Equatable {
    let id: String
    let assignment: TeacherAssignment
    var courseName: String = ""
    var courseCode: String = ""
    var batchName: String = ""
}

@MainActor
final class TeacherDashboardViewModel: ObservableObject {
    @Published var assignments: [TeacherAssignmentDisplay] = []
    @Published var todayRoutines: [RoutineDisplayItem] = []
    @Published var totalStudents: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDashboard(teacherId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            async let assignmentsTask = TeacherAssignmentService.shared.fetchAssignments(forTeacher: teacherId)
            async let routinesTask = RoutineService.shared.fetchRoutines(forTeacher: teacherId)
            async let coursesTask = CourseService.shared.fetchAll()
            async let batchesTask = BatchService.shared.fetchAll()

            let rawAssignments = try await assignmentsTask
            let routines = try await routinesTask
            let courses = try await coursesTask
            let batches = try await batchesTask

            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            let batchMap = Dictionary(uniqueKeysWithValues: batches.compactMap { b -> (String, Batch)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })

            assignments = rawAssignments.compactMap { a -> TeacherAssignmentDisplay? in
                guard let id = a.id else { return nil }
                return TeacherAssignmentDisplay(
                    id: id,
                    assignment: a,
                    courseName: courseMap[a.courseId]?.name ?? "Unknown",
                    courseCode: courseMap[a.courseId]?.code ?? "",
                    batchName: batchMap[a.batchId]?.name ?? "Unknown"
                )
            }

            // Today's routines
            let today = Weekday.today
            todayRoutines = routines
                .filter { $0.day == today }
                .sorted { $0.startTime < $1.startTime }
                .map { routine in
                    RoutineDisplayItem(
                        id: routine.id ?? UUID().uuidString,
                        routine: routine,
                        courseName: courseMap[routine.courseId]?.name ?? "Unknown",
                        courseCode: courseMap[routine.courseId]?.code ?? "",
                        teacherName: "",
                        isActive: routine.isCurrentlyActive
                    )
                }

            // Count unique batches for student count
            let batchIds = Set(rawAssignments.map(\.batchId))
            var count = 0
            for batchId in batchIds {
                let students = try await UserService.shared.fetchStudents(inBatch: batchId)
                count += students.count
            }
            totalStudents = count

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct TeacherDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TeacherDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.primary)
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            greetingCard
                            statsGrid
                            todaySection
                            assignmentsSection
                        }
                        .padding(AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusBar()
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        guard let user = appState.currentUser else { return }
        await viewModel.loadDashboard(teacherId: user.id)
    }

    // MARK: - Greeting

    private var greetingCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(appState.currentUser?.name ?? "Teacher")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.primaryGradient)

                Text(DateFormatters.mediumDate.string(from: Date()))
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 56, height: 56)

                Text(appState.currentUser?.initials ?? "T")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
            }
        }
        .cwCard()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: AppTheme.spacingMD) {
            statCard(icon: "book.fill", value: "\(viewModel.assignments.count)", label: "Courses", color: AppTheme.primary)
            statCard(icon: "person.3.fill", value: "\(viewModel.totalStudents)", label: "Students", color: AppTheme.secondary)
            statCard(icon: "calendar.badge.clock", value: "\(viewModel.todayRoutines.count)", label: "Today", color: AppTheme.accent)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cwCard()
    }

    // MARK: - Today's Schedule

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Today's Classes")
                .cwSectionHeader()

            if viewModel.todayRoutines.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.safe)
                    Text("No classes scheduled for today!")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .cwCard()
            } else {
                ForEach(viewModel.todayRoutines) { item in
                    NavigationLink(destination: AttendanceMarkingView(routine: item)) {
                        TeacherRoutineRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Assignments

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("My Courses")
                .cwSectionHeader()

            ForEach(viewModel.assignments) { assignment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.courseName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: AppTheme.spacingSM) {
                            Label(assignment.courseCode, systemImage: "number")
                            Label(assignment.batchName, systemImage: "person.3")
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .cwCard()
            }
        }
    }
}

// MARK: - Teacher Routine Row

struct TeacherRoutineRow: View {
    let item: RoutineDisplayItem

    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            // Time column
            VStack(spacing: 2) {
                Text(DateFormatters.formatTime(item.routine.startTime))
                    .font(.caption.weight(.semibold))
                Text(DateFormatters.formatTime(item.routine.endTime))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(width: 60)

            // Accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(item.isActive ? AppTheme.safe : AppTheme.primary)
                .frame(width: 3, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.courseName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: AppTheme.spacingSM) {
                    Label(item.routine.room.isEmpty ? "TBA" : item.routine.room, systemImage: "mappin")
                    Text("•")
                    Text(item.courseCode)
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            if item.isActive {
                Text("LIVE")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.safe))
            } else {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .cwCard()
    }
}

#Preview("Teacher Dashboard") {
    TeacherDashboardView()
        .environmentObject(MockData.makeTeacherAppState())
}

#Preview("Teacher Routine Row") {
    TeacherRoutineRow(item: MockData.routineDisplayItems[0])
        .padding()
        .background(AppTheme.background)
}
