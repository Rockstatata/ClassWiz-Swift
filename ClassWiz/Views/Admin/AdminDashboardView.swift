// AdminDashboardView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var totalUsers = 0
    @Published var totalStudents = 0
    @Published var totalTeachers = 0
    @Published var totalCourses = 0
    @Published var totalBatches = 0
    @Published var totalRoutines = 0
    @Published var totalAssignments = 0
    @Published var isLoading = false

    func loadDashboard() async {
        isLoading = true

        do {
            async let usersTask = UserService.shared.fetchAllUsers()
            async let coursesTask = CourseService.shared.fetchAll()
            async let batchesTask = BatchService.shared.fetchAll()
            async let routinesTask = RoutineService.shared.fetchAll()
            async let assignmentsTask = TeacherAssignmentService.shared.fetchAll()

            let users = try await usersTask
            let courses = try await coursesTask
            let batches = try await batchesTask
            let routines = try await routinesTask
            let assignments = try await assignmentsTask

            totalUsers = users.count
            totalStudents = users.filter { $0.role == .student }.count
            totalTeachers = users.filter { $0.role == .teacher }.count
            totalCourses = courses.count
            totalBatches = batches.count
            totalRoutines = routines.count
            totalAssignments = assignments.count
        } catch {
            // silent
        }

        isLoading = false
    }
}

struct AdminDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AdminDashboardViewModel()

    let columns = [
        GridItem(.flexible(), spacing: AppTheme.spacingMD),
        GridItem(.flexible(), spacing: AppTheme.spacingMD)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingMD) {
                            // Greeting
                            greetingSection

                            // Stats Grid
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingMD) {
                                adminStatCard(icon: "person.3.fill", value: "\(viewModel.totalStudents)", label: "Students", color: AppTheme.primary)
                                adminStatCard(icon: "person.crop.rectangle.fill", value: "\(viewModel.totalTeachers)", label: "Teachers", color: AppTheme.secondary)
                                adminStatCard(icon: "book.fill", value: "\(viewModel.totalCourses)", label: "Courses", color: AppTheme.accent)
                                adminStatCard(icon: "building.2.fill", value: "\(viewModel.totalBatches)", label: "Batches", color: AppTheme.warning)
                                adminStatCard(icon: "clock.fill", value: "\(viewModel.totalRoutines)", label: "Routines", color: AppTheme.safe)
                                adminStatCard(icon: "link", value: "\(viewModel.totalAssignments)", label: "Assignments", color: AppTheme.critical)
                            }

                            // Quick Actions
                            quickActions
                        }
                        .padding(AppTheme.spacingMD)
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusBar()
                }
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                Text(appState.currentUser?.name ?? "Admin")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 48, height: 48)

                Image(systemName: "shield.fill")
                    .foregroundColor(.white)
            }
        }
        .cwCard()
    }

    private func adminStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppTheme.spacingSM) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(label)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }
        }
        .cwCard()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text("Quick Actions")
                .cwSectionHeader()

            NavigationLink(destination: CourseFormView(mode: .add)) {
                quickActionRow(icon: "plus.circle.fill", title: "Add New Course", color: AppTheme.primary)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: BatchFormView(mode: .add)) {
                quickActionRow(icon: "plus.circle.fill", title: "Add New Batch", color: AppTheme.secondary)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: UserCreationView()) {
                quickActionRow(icon: "person.badge.plus", title: "Create User Account", color: AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func quickActionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .cwCard()
    }
}

#Preview("Admin Dashboard") {
    AdminDashboardView()
        .environmentObject(MockData.makeAdminAppState())
}

#Preview("Admin Dashboard – Dark") {
    AdminDashboardView()
        .environmentObject(MockData.makeAdminAppState())
        .preferredColorScheme(.dark)
}
