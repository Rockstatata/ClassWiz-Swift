// TeacherTabView.swift
// ClassWiz – Views/Teacher

import SwiftUI

struct TeacherTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    let tabs: [CWTabBarItem] = [
        CWTabBarItem(id: 0, title: "Dashboard", icon: "house", selectedIcon: "house.fill"),
        CWTabBarItem(id: 1, title: "Schedule", icon: "calendar", selectedIcon: "calendar"),
        CWTabBarItem(id: 2, title: "Courses", icon: "book", selectedIcon: "book.fill"),
        CWTabBarItem(id: 3, title: "Tasks", icon: "doc.text", selectedIcon: "doc.text.fill"),
       
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                switch selectedTab {
                case 0:
                    TeacherDashboardView()
                case 1:
                    TeacherScheduleView()
                case 2:
                    TeacherCoursesView()
                case 3:
                    TeacherAssignmentsView()	
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
