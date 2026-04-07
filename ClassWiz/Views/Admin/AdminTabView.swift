// AdminTabView.swift
// ClassWiz – Views/Admin

import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    @State private var pendingCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            CourseManagementView()
                .tabItem { Label("Courses", systemImage: "book.fill") }
                .tag(1)

            BatchManagementView()
                .tabItem { Label("Batches", systemImage: "person.3.fill") }
                .tag(2)

            RoutineManagementView()
                .tabItem { Label("Routines", systemImage: "clock.fill") }
                .tag(3)

            AdminMoreView(pendingCount: pendingCount)
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
                .badge(pendingCount > 0 ? pendingCount : 0)
                .tag(4)
        }
        .tint(AppTheme.primary)
        .onChange(of: selectedTab) { _, _ in HapticManager.selection() }
        .task { await refreshPendingCount() }
    }

    private func refreshPendingCount() async {
        pendingCount = (try? await UserService.shared.fetchPendingApprovals())?.count ?? 0
    }
}

// MARK: - Admin More View

struct AdminMoreView: View {
    @EnvironmentObject private var appState: AppState
    var pendingCount: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    // Pending approvals — shown prominently if there are any
                    if pendingCount > 0 {
                        Section {
                            NavigationLink(destination: PendingApprovalsView()) {
                                HStack {
                                    Label("Pending Approvals", systemImage: "person.badge.clock.fill")
                                        .foregroundColor(AppTheme.warning)
                                    Spacer()
                                    Text("\(pendingCount)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(AppTheme.warning))
                                }
                            }
                        } header: {
                            Text("⚠️ Action Required")
                        }
                    }

                    Section("Management") {
                        NavigationLink(destination: PendingApprovalsView()) {
                            Label("Pending Approvals", systemImage: "person.badge.clock.fill")
                                .badge(pendingCount > 0 ? pendingCount : 0)
                        }

                        NavigationLink(destination: TeacherAssignmentManagementView()) {
                            Label("Teacher Assignments", systemImage: "person.badge.plus")
                        }

                        NavigationLink(destination: UserManagementView()) {
                            Label("All Users", systemImage: "person.2.fill")
                        }
                    }

                    Section("Account") {
                        NavigationLink(destination: ProfileView()) {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("More")
        }
    }
}
