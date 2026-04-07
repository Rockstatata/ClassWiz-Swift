// WhatIfSimulatorView.swift
// ClassWiz – Views/Student

import SwiftUI
import Combine

@MainActor
final class WhatIfViewModel: ObservableObject {
    @Published var courseStats: [CourseAttendanceStat] = []
    @Published var selectedCourseIndex: Int = 0
    @Published var futurePresentCount: Int = 0
    @Published var futureAbsentCount: Int = 0
    @Published var isLoading = false

    var selectedStat: CourseAttendanceStat? {
        guard courseStats.indices.contains(selectedCourseIndex) else { return nil }
        return courseStats[selectedCourseIndex]
    }

    var projectedPercentage: Double {
        guard let stat = selectedStat else { return 0 }
        let totalFuture = stat.totalClasses + futurePresentCount + futureAbsentCount
        let presentFuture = stat.presentCount + futurePresentCount
        guard totalFuture > 0 else { return 0 }
        return (Double(presentFuture) / Double(totalFuture)) * 100
    }

    var projectedRisk: RiskLevel {
        RiskLevel.from(percentage: projectedPercentage)
    }

    var projectedTotal: Int {
        (selectedStat?.totalClasses ?? 0) + futurePresentCount + futureAbsentCount
    }

    var projectedPresent: Int {
        (selectedStat?.presentCount ?? 0) + futurePresentCount
    }

    var recoveryMessage: String {
        guard let stat = selectedStat else { return "" }
        let currentPct = stat.percentage

        if projectedPercentage >= 75 && currentPct < 75 {
            return "✅ This scenario would bring you above 75%!"
        } else if projectedPercentage < 75 && currentPct >= 75 {
            return "⚠️ This scenario would drop you below 75%!"
        } else if projectedPercentage < 75 {
            // How many more present classes needed?
            let neededPresent = Int(ceil((0.75 * Double(projectedTotal) - Double(projectedPresent)) / 0.25))
            if neededPresent > 0 {
                return "📊 You'd need \(neededPresent) more consecutive classes to reach 75%."
            }
        }
        return ""
    }

    func loadData(studentId: String, batchId: String?) async {
        isLoading = true
        let vm = StudentAttendanceViewModel()
        await vm.loadAttendance(studentId: studentId, batchId: batchId)
        courseStats = vm.courseStats
        isLoading = false
    }

    func reset() {
        futurePresentCount = 0
        futureAbsentCount = 0
    }
}

struct WhatIfSimulatorView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = WhatIfViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.primary)
                } else if viewModel.courseStats.isEmpty {
                    EmptyStateView(
                        icon: "slider.horizontal.3",
                        title: "No Data",
                        subtitle: "Attendance data is needed to run simulations."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            courseSelector
                            currentStatsCard
                            simulatorCard
                            projectedResultCard

                            if !viewModel.recoveryMessage.isEmpty {
                                recoveryCard
                            }
                        }
                        .padding(AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("What-If Simulator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.reset()
                        HapticManager.lightImpact()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.primary)
                }
            }
            .task {
                guard let user = appState.currentUser else { return }
                await viewModel.loadData(studentId: user.id, batchId: user.batchId)
            }
        }
    }

    // MARK: - Course Selector

    private var courseSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Select Course")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingSM) {
                    ForEach(Array(viewModel.courseStats.enumerated()), id: \.element.id) { index, stat in
                        Button {
                            withAnimation(AppTheme.quickAnimation) {
                                viewModel.selectedCourseIndex = index
                                viewModel.reset()
                            }
                            HapticManager.selection()
                        } label: {
                            Text(stat.course.code)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(viewModel.selectedCourseIndex == index ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.selectedCourseIndex == index ? AppTheme.primary : AppTheme.surfaceSecondary)
                                )
                        }
                    }
                }
            }
        }
        .cwCard()
    }

    // MARK: - Current Stats

    private var currentStatsCard: some View {
        Group {
            if let stat = viewModel.selectedStat {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        Text("Current Status")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .textCase(.uppercase)

                        Text(stat.course.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: AppTheme.spacingMD) {
                            StatPill(value: "\(stat.presentCount)", label: "Present", color: AppTheme.safe)
                            StatPill(value: "\(stat.absentCount)", label: "Absent", color: AppTheme.critical)
                            StatPill(value: "\(stat.totalClasses)", label: "Total", color: AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    CircularProgressView(
                        progress: stat.percentage / 100,
                        lineWidth: 6,
                        size: 60
                    )
                }
                .cwCard()
            }
        }
    }

    // MARK: - Simulator Controls

    private var simulatorCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            Text("Simulate Future")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)

            // Present stepper
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.safe)

                Text("Classes to attend")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if viewModel.futurePresentCount > 0 {
                            viewModel.futurePresentCount -= 1
                            HapticManager.lightImpact()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.futurePresentCount > 0 ? AppTheme.primary : AppTheme.textSecondary.opacity(0.3))
                    }

                    Text("\(viewModel.futurePresentCount)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 36)

                    Button {
                        viewModel.futurePresentCount += 1
                        HapticManager.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }

            Divider()

            // Absent stepper
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.critical)

                Text("Classes to miss")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if viewModel.futureAbsentCount > 0 {
                            viewModel.futureAbsentCount -= 1
                            HapticManager.lightImpact()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.futureAbsentCount > 0 ? AppTheme.critical : AppTheme.textSecondary.opacity(0.3))
                    }

                    Text("\(viewModel.futureAbsentCount)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 36)

                    Button {
                        viewModel.futureAbsentCount += 1
                        HapticManager.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.critical)
                    }
                }
            }
        }
        .cwCard()
    }

    // MARK: - Projected Result

    private var projectedResultCard: some View {
        HStack(spacing: AppTheme.spacingLG) {
            CircularProgressView(
                progress: viewModel.projectedPercentage / 100,
                lineWidth: 8,
                size: 80,
                riskLevel: viewModel.projectedRisk
            )

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                Text("Projected Result")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)

                Text("\(String(format: "%.1f", viewModel.projectedPercentage))%")
                    .font(.title2.weight(.bold))
                    .foregroundColor(viewModel.projectedRisk.color)

                RiskBadge(level: viewModel.projectedRisk)
            }

            Spacer()
        }
        .cwCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .stroke(viewModel.projectedRisk.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Recovery Card

    private var recoveryCard: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppTheme.warning)

            Text(viewModel.recoveryMessage)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .cwCard()
    }
}

#Preview("What-If Simulator") {
    WhatIfSimulatorView()
        .environmentObject(MockData.makeStudentAppState())
}

#Preview("What-If – Dark") {
    WhatIfSimulatorView()
        .environmentObject(MockData.makeStudentAppState())
        .preferredColorScheme(.dark)
}
