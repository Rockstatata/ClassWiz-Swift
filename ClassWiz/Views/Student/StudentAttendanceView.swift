// StudentAttendanceView.swift
// ClassWiz – Views/Student

import SwiftUI

struct StudentAttendanceView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = StudentAttendanceViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.primary)
                } else if viewModel.courseStats.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Attendance Data",
                        subtitle: "Your attendance records will appear here once your teachers start marking attendance."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            // Overall summary card
                            overallSummaryCard
                                .padding(.horizontal, AppTheme.spacingMD)

                            // Course-wise cards
                            VStack(spacing: AppTheme.spacingMD) {
                                HStack {
                                    Text("Course Breakdown")
                                        .cwSectionHeader()
                                    Spacer()
                                }
                                .padding(.horizontal, AppTheme.spacingMD)

                                ForEach(viewModel.courseStats) { stat in
                                    NavigationLink(destination: AttendanceDetailView(stat: stat)) {
                                        CourseAttendanceCard(stat: stat)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, AppTheme.spacingMD)
                                }
                            }

                            // Intelligence Section
                            if viewModel.courseStats.contains(where: { $0.risk != .safe }) {
                                intelligenceSection
                                    .padding(.horizontal, AppTheme.spacingMD)
                            }
                        }
                        .padding(.vertical, AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("Attendance")
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
        await viewModel.loadAttendance(studentId: user.id, batchId: user.batchId)
    }

    // MARK: - Overall Summary

    private var overallSummaryCard: some View {
        HStack(spacing: AppTheme.spacingLG) {
            CircularProgressView(
                progress: viewModel.overallPercentage / 100,
                lineWidth: 10,
                size: 90
            )

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Overall Attendance")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.textSecondary)

                RiskBadge(level: viewModel.overallRisk)

                HStack(spacing: AppTheme.spacingMD) {
                    StatPill(value: "\(viewModel.courseStats.count)", label: "Courses", color: AppTheme.primary)
                }
            }

            Spacer()
        }
        .cwCard()
    }

    // MARK: - Intelligence Section

    private var intelligenceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.warning)
                Text("Attendance Intelligence")
                    .cwSectionHeader()
            }

            ForEach(viewModel.courseStats.filter { $0.risk != .safe }) { stat in
                HStack(spacing: AppTheme.spacingMD) {
                    RiskBadge(level: stat.risk, compact: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.course.code)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        if stat.classesNeededFor75 > 0 {
                            Text("Attend next \(stat.classesNeededFor75) classes to reach 75%")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(AppTheme.spacingMD)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSM)
                        .fill(stat.risk.color.opacity(0.06))
                )
            }
        }
        .cwCard()
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    var color: Color = AppTheme.primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - Course Attendance Card

struct CourseAttendanceCard: View {
    let stat: CourseAttendanceStat

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.course.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(stat.course.code)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                RiskBadge(level: stat.risk, compact: true)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stat.risk.color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(stat.risk.color)
                        .frame(width: geo.size.width * min(stat.percentage / 100, 1))
                }
            }
            .frame(height: 6)

            // Stats row
            HStack {
                Text("\(String(format: "%.1f", stat.percentage))%")
                    .font(.headline.weight(.bold))
                    .foregroundColor(stat.risk.color)

                Spacer()

                HStack(spacing: AppTheme.spacingMD) {
                    Label("\(stat.presentCount)P", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(AppTheme.safe)

                    Label("\(stat.absentCount)A", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(AppTheme.critical)

                    Text("\(stat.totalClasses) total")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Recovery or allowance message
            if stat.risk != .safe && stat.classesNeededFor75 > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                    Text("Attend next \(stat.classesNeededFor75) classes to reach 75%")
                        .font(.caption2)
                }
                .foregroundColor(stat.risk.color)
            } else if stat.maxAllowedAbsences > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.caption2)
                    Text("You can miss up to \(stat.maxAllowedAbsences) more classes")
                        .font(.caption2)
                }
                .foregroundColor(AppTheme.safe)
            }
        }
        .cwCard()
    }
}

// MARK: - Attendance Detail View

struct AttendanceDetailView: View {
    @EnvironmentObject private var appState: AppState
    let stat: CourseAttendanceStat
    @State private var records: [AttendanceRecord] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.spacingMD) {
                    // Summary header
                    HStack(spacing: AppTheme.spacingLG) {
                        CircularProgressView(
                            progress: stat.percentage / 100,
                            lineWidth: 8,
                            size: 70
                        )

                        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                            Text(stat.course.name)
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            RiskBadge(level: stat.risk)

                            HStack(spacing: AppTheme.spacingMD) {
                                StatPill(value: "\(stat.presentCount)", label: "Present", color: AppTheme.safe)
                                StatPill(value: "\(stat.absentCount)", label: "Absent", color: AppTheme.critical)
                                StatPill(value: "\(stat.totalClasses)", label: "Total", color: AppTheme.primary)
                            }
                        }

                        Spacer()
                    }
                    .cwCard()

                    // Records list
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        Text("Attendance History")
                            .cwSectionHeader()

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if records.isEmpty {
                            Text("No records found.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(records) { record in
                                HStack {
                                    Image(systemName: record.status.icon)
                                        .foregroundColor(record.status.color)

                                    Text(record.dateString)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)

                                    Spacer()

                                    Text(record.status.rawValue.capitalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(record.status.color)
                                }
                                .padding(.vertical, 6)

                                if record.id != records.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .cwCard()
                }
                .padding(AppTheme.spacingMD)
            }
        }
        .navigationTitle(stat.course.code)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let userId = appState.currentUser?.id {
                records = await StudentAttendanceViewModel().fetchDetailRecords(
                    studentId: userId,
                    courseId: stat.id
                )
            }
            isLoading = false
        }
    }
}

#Preview("Attendance – Student") {
    StudentAttendanceView()
        .environmentObject(MockData.makeStudentAppState())
}

#Preview("Course Attendance Card – Safe") {
    CourseAttendanceCard(stat: MockData.courseStats[0])
        .padding()
}

#Preview("Course Attendance Card – Critical") {
    CourseAttendanceCard(stat: MockData.courseStats[2])
        .padding()
}
