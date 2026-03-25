// RootRouter.swift
// ClassWiz – Core

import SwiftUI

struct RootRouter: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch appState.authState {
            case .loading:
                LoadingView()
                    .transition(.opacity)

            case .signedOut:
                AuthGateView()
                    .transition(.move(edge: .leading).combined(with: .opacity))

            case .pendingApproval:
                PendingApprovalView()
                    .transition(.opacity)

            case .signedIn(let role):
                mainView(for: role)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(AppTheme.defaultAnimation, value: appState.authState)
        .overlay(alignment: .top) {
            if appState.isOffline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(AppTheme.quickAnimation, value: appState.isOffline)
    }

    @ViewBuilder
    private func mainView(for role: UserRole) -> some View {
        switch role {
        case .student: StudentTabView()
        case .teacher: TeacherTabView()
        case .admin:   AdminTabView()
        }
    }
}

#Preview("Root – Loading") {
    RootRouter()
        .environmentObject({ let s = AppState(); s.authState = .loading; return s }())
}

#Preview("Root – Sign In") {
    RootRouter()
        .environmentObject({ let s = AppState(); s.authState = .signedOut; return s }())
}

#Preview("Root – Pending") {
    RootRouter()
        .environmentObject({
            let s = AppState()
            s.setPendingApproval(user: AppUser(id: "1", name: "Test User", email: "t@t.com", role: .student, isApproved: false))
            return s
        }())
}

#Preview("Root – Student") {
    RootRouter()
        .environmentObject(MockData.makeStudentAppState())
}
