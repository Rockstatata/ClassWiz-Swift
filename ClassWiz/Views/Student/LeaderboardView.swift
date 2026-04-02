// LeaderboardView.swift
// ClassWiz – Views/Student

import SwiftUI
import Combine

struct LeaderboardEntry: Identifiable, Equatable {
    let id: String  // studentId
    let name: String
    let percentage: Double
    let risk: RiskLevel
    let isCurrentUser: Bool
    var rank: Int = 0
}

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var courses: [Course] = []
    @Published var selectedCourseIndex: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    var selectedCourse: Course? {
        guard courses.indices.contains(selectedCourseIndex) else { return nil }
        return courses[selectedCourseIndex]
    }

    var currentUserRank: Int? {
        entries.first(where: \.isCurrentUser)?.rank
    }

    func loadData(batchId: String?, currentUserId: String) async {
        guard let batchId else { return }
        isLoading = true

        do {
            courses = try await CourseService.shared.fetchActive()

            if !courses.isEmpty {
                await loadLeaderboard(batchId: batchId, currentUserId: currentUserId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadLeaderboard(batchId: String, currentUserId: String) async {
        guard let course = selectedCourse, let courseId = course.id else { return }

        do {
            let students = try await UserService.shared.fetchStudents(inBatch: batchId)
            let records = try await AttendanceService.shared.fetchAttendance(batchId: batchId, courseId: courseId)

            let grouped = Dictionary(grouping: records, by: \.studentId)

            var leaderboard: [LeaderboardEntry] = students.map { student in
                let studentRecords = grouped[student.id] ?? []
                let total = studentRecords.count
                let present = studentRecords.filter { $0.status == .present }.count
                let percentage = total > 0 ? (Double(present) / Double(total)) * 100 : 0

                return LeaderboardEntry(
                    id: student.id,
                    name: student.name,
                    percentage: percentage,
                    risk: RiskLevel.from(percentage: percentage),
                    isCurrentUser: student.id == currentUserId
                )
            }

            leaderboard.sort { $0.percentage > $1.percentage }
            for i in leaderboard.indices {
                leaderboard[i].rank = i + 1
            }

            entries = leaderboard
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.primary)
                } else if viewModel.courses.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No Courses",
                        subtitle: "Leaderboard will be available once courses are set up."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            courseFilter
                            if let rank = viewModel.currentUserRank {
                                yourRankCard(rank: rank)
                            }
                            leaderboardList
                        }
                        .padding(AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusBar()
                }
            }
            .task {
                guard let user = appState.currentUser else { return }
                await viewModel.loadData(batchId: user.batchId, currentUserId: user.id)
            }
        }
    }

    // MARK: - Course Filter

    private var courseFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(Array(viewModel.courses.enumerated()), id: \.element.id) { index, course in
                    Button {
                        viewModel.selectedCourseIndex = index
                        HapticManager.selection()
                        Task {
                            guard let user = appState.currentUser else { return }
                            await viewModel.loadLeaderboard(
                                batchId: user.batchId ?? "",
                                currentUserId: user.id
                            )
                        }
                    } label: {
                        Text(course.code)
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

    // MARK: - Your Rank

    private func yourRankCard(rank: Int) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 48, height: 48)

                Text("#\(rank)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Rank")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                if let entry = viewModel.entries.first(where: \.isCurrentUser) {
                    Text("\(String(format: "%.1f", entry.percentage))% attendance")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }

            Spacer()

            Text("out of \(viewModel.entries.count)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .cwCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.entries) { entry in
                leaderboardRow(entry)

                if entry.id != viewModel.entries.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .cwCard()
    }

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.title3)
                        .foregroundColor(medalColor(rank: entry.rank))
                } else {
                    Text("\(entry.rank)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(width: 32)

            // Avatar
            ZStack {
                Circle()
                    .fill(entry.isCurrentUser ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.surfaceSecondary, AppTheme.surfaceSecondary], startPoint: .top, endPoint: .bottom))
                    .frame(width: 36, height: 36)

                Text(String(entry.name.prefix(1)))
                    .font(.caption.weight(.bold))
                    .foregroundColor(entry.isCurrentUser ? .white : AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.isCurrentUser ? "You" : entry.name)
                        .font(.subheadline.weight(entry.isCurrentUser ? .bold : .medium))
                        .foregroundColor(AppTheme.textPrimary)

                    if entry.isCurrentUser {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.warning)
                    }
                }
            }

            Spacer()

            HStack(spacing: AppTheme.spacingSM) {
                Text("\(String(format: "%.0f", entry.percentage))%")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundColor(entry.risk.color)

                RiskBadge(level: entry.risk, compact: true)
            }
        }
        .padding(.vertical, AppTheme.spacingSM)
        .background(entry.isCurrentUser ? AppTheme.primary.opacity(0.05) : Color.clear)
    }

    private func medalColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return AppTheme.textSecondary
        }
    }
}
