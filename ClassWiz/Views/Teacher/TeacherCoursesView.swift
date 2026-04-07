// TeacherCoursesView.swift
// ClassWiz – Views/Teacher

import SwiftUI
import Combine

@MainActor
final class TeacherAnalyticsViewModel: ObservableObject {
    @Published var courseAssignments: [TeacherAssignmentDisplay] = []
    @Published var isLoading = false

    func loadCourses(teacherId: String) async {
        isLoading = true

        do {
            let assignments = try await TeacherAssignmentService.shared.fetchAssignments(forTeacher: teacherId)
            let courses = try await CourseService.shared.fetchAll()
            let batches = try await BatchService.shared.fetchAll()

            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            let batchMap = Dictionary(uniqueKeysWithValues: batches.compactMap { b -> (String, Batch)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })

            courseAssignments = assignments.compactMap { a -> (TeacherAssignmentDisplay)? in
                guard let id = a.id else { return nil }
                return TeacherAssignmentDisplay(
                    id: id,
                    assignment: a,
                    courseName: courseMap[a.courseId]?.name ?? "Unknown",
                    courseCode: courseMap[a.courseId]?.code ?? "",
                    batchName: batchMap[a.batchId]?.name ?? "Unknown"
                )
            }
        } catch {
            // silent
        }

        isLoading = false
    }
}

struct TeacherCoursesView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TeacherAnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                } else if viewModel.courseAssignments.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Courses Assigned",
                        subtitle: "You don't have any course assignments yet."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.spacingMD) {
                            ForEach(viewModel.courseAssignments) { assignment in
                                NavigationLink(destination: CourseAnalyticsView(assignment: assignment)) {
                                    courseCard(assignment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("My Courses")
            .refreshable {
                guard let user = appState.currentUser else { return }
                await viewModel.loadCourses(teacherId: user.id)
            }
            .task {
                guard let user = appState.currentUser else { return }
                await viewModel.loadCourses(teacherId: user.id)
            }
        }
    }

    private func courseCard(_ assignment: TeacherAssignmentDisplay) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 48, height: 48)

                Image(systemName: "book.fill")
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.courseName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: AppTheme.spacingSM) {
                    Text(assignment.courseCode)
                    Text("•")
                    Text(assignment.batchName)
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chart.bar.fill")
                .foregroundColor(AppTheme.primary)
                .font(.title3)
        }
        .cwCard()
    }
}

// MARK: - Course Analytics View

struct CourseAnalyticsDetailData: Equatable {
    let totalStudents: Int
    let totalClasses: Int
    let averageAttendance: Double
    let averageRisk: RiskLevel
    let studentStats: [StudentAnalyticItem]
}

struct StudentAnalyticItem: Identifiable, Equatable {
    let id: String
    let name: String
    let percentage: Double
    let risk: RiskLevel
    let presentCount: Int
    let absentCount: Int
}

@MainActor
final class CourseAnalyticsDetailViewModel: ObservableObject {
    @Published var data: CourseAnalyticsDetailData?
    @Published var isLoading = false

    func loadAnalytics(courseId: String, batchId: String) async {
        isLoading = true

        do {
            let students = try await UserService.shared.fetchStudents(inBatch: batchId)
            let records = try await AttendanceService.shared.fetchAllAttendance(courseId: courseId)

            let grouped = Dictionary(grouping: records, by: \.studentId)

            // Get unique dates to determine total classes
            let uniqueDates = Set(records.map { Calendar.current.startOfDay(for: $0.date) })
            let totalClasses = uniqueDates.count

            var studentStats: [StudentAnalyticItem] = []

            for student in students {
                let studentRecords = grouped[student.id] ?? []
                let present = studentRecords.filter { $0.status == .present }.count
                let absent = studentRecords.filter { $0.status == .absent }.count
                let total = present + absent
                let percentage = total > 0 ? (Double(present) / Double(total)) * 100 : 0

                studentStats.append(StudentAnalyticItem(
                    id: student.id,
                    name: student.name,
                    percentage: percentage,
                    risk: RiskLevel.from(percentage: percentage),
                    presentCount: present,
                    absentCount: absent
                ))
            }

            studentStats.sort { $0.percentage < $1.percentage } // Worst first

            let avgPercentage = studentStats.isEmpty ? 0 :
                studentStats.reduce(0.0) { $0 + $1.percentage } / Double(studentStats.count)

            data = CourseAnalyticsDetailData(
                totalStudents: students.count,
                totalClasses: totalClasses,
                averageAttendance: avgPercentage,
                averageRisk: RiskLevel.from(percentage: avgPercentage),
                studentStats: studentStats
            )
        } catch {
            // silent
        }

        isLoading = false
    }
}

struct CourseAnalyticsView: View {
    let assignment: TeacherAssignmentDisplay
    @StateObject private var viewModel = CourseAnalyticsDetailViewModel()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(AppTheme.primary)
            } else if let data = viewModel.data {
                ScrollView {
                    VStack(spacing: AppTheme.spacingMD) {
                        // Summary
                        summaryCard(data)

                        // Risk Distribution
                        riskDistribution(data)

                        // Student list
                        studentSection(data)
                    }
                    .padding(AppTheme.spacingMD)
                }
            }
        }
        .navigationTitle(assignment.courseCode)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAnalytics(
                courseId: assignment.assignment.courseId,
                batchId: assignment.assignment.batchId
            )
        }
    }

    private func summaryCard(_ data: CourseAnalyticsDetailData) -> some View {
        HStack(spacing: AppTheme.spacingLG) {
            CircularProgressView(
                progress: data.averageAttendance / 100,
                lineWidth: 8,
                size: 80
            )

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text(assignment.courseName)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(assignment.batchName)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: AppTheme.spacingMD) {
                    StatPill(value: "\(data.totalStudents)", label: "Students", color: AppTheme.primary)
                    StatPill(value: "\(data.totalClasses)", label: "Classes", color: AppTheme.secondary)
                }
            }

            Spacer()
        }
        .cwCard()
    }

    private func riskDistribution(_ data: CourseAnalyticsDetailData) -> some View {
        let safe = data.studentStats.filter { $0.risk == .safe }.count
        let warning = data.studentStats.filter { $0.risk == .warning }.count
        let critical = data.studentStats.filter { $0.risk == .critical }.count
        let total = max(data.studentStats.count, 1)

        return VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Risk Distribution")
                .cwSectionHeader()

            // Bar chart
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if safe > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.safe)
                            .frame(width: geo.size.width * CGFloat(safe) / CGFloat(total))
                    }
                    if warning > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.warning)
                            .frame(width: geo.size.width * CGFloat(warning) / CGFloat(total))
                    }
                    if critical > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.critical)
                            .frame(width: geo.size.width * CGFloat(critical) / CGFloat(total))
                    }
                }
            }
            .frame(height: 12)

            // Legend
            HStack(spacing: AppTheme.spacingMD) {
                legendItem(color: AppTheme.safe, label: "Safe", count: safe)
                legendItem(color: AppTheme.warning, label: "Warning", count: warning)
                legendItem(color: AppTheme.critical, label: "Critical", count: critical)
            }
        }
        .cwCard()
    }

    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label): \(count)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func studentSection(_ data: CourseAnalyticsDetailData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Students")
                .cwSectionHeader()

            ForEach(data.studentStats) { student in
                HStack(spacing: AppTheme.spacingMD) {
                    ZStack {
                        Circle()
                            .fill(student.risk.color.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Text(String(student.name.prefix(1)))
                            .font(.caption.weight(.bold))
                            .foregroundColor(student.risk.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("\(student.presentCount)P / \(student.absentCount)A")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Text("\(String(format: "%.0f", student.percentage))%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundColor(student.risk.color)

                    RiskBadge(level: student.risk, compact: true)
                }
                .padding(.vertical, 4)

                if student.id != data.studentStats.last?.id {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .cwCard()
    }
}
