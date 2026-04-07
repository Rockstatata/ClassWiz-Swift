// TeacherTabView.swift
// ClassWiz – Views/Teacher

import SwiftUI

struct TeacherTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TeacherDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            TeacherScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(1)

            TeacherCoursesView()
                .tabItem {
                    Label("Courses", systemImage: "book.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(AppTheme.primary)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.selection()
        }
    }
}
