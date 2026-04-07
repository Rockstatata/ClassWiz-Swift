// StudentTabView.swift
// ClassWiz – Views/Student

import SwiftUI

struct StudentTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StudentRoutineView()
                .tabItem {
                    Label("Routine", systemImage: "calendar")
                }
                .tag(0)

            StudentAttendanceView()
                .tabItem {
                    Label("Attendance", systemImage: "chart.bar.fill")
                }
                .tag(1)

            WhatIfSimulatorView()
                .tabItem {
                    Label("Simulator", systemImage: "slider.horizontal.3")
                }
                .tag(2)

            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(AppTheme.primary)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.selection()
        }
    }
}
