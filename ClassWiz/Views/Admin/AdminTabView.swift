// AdminTabView.swift
// ClassWiz – Views/Admin

import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    let tabs: [CWTabBarItem] = [
        CWTabBarItem(id: 0, title: "Dashboard", icon: "house", selectedIcon: "house.fill"),
        CWTabBarItem(id: 1, title: "Batches", icon: "graduationcap", selectedIcon: "graduationcap.fill"),
        CWTabBarItem(id: 2, title: "Courses", icon: "book", selectedIcon: "book.fill"),
        CWTabBarItem(id: 3, title: "Routines", icon: "calendar", selectedIcon: "calendar"),
        CWTabBarItem(id: 4, title: "Users", icon: "person.2", selectedIcon: "person.2.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                switch selectedTab {
                case 0:
                    AdminDashboardView()
                case 1:
                    BatchManagementView()
                case 2:
                    CourseManagementView()
                case 3:
                    RoutineManagementView()
                case 4:
                    UserManagementView()
                default:
                    EmptyView()
                }
                
                ClassWizTabBar(items: tabs, selection: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
            .onChange(of: selectedTab) { _ in
                HapticManager.selection()
            }
        }
    }
}
