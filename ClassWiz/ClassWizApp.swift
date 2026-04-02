//
//  ClassWizApp.swift
//  ClassWiz
//
//  Created by Sarwad Hasan  on 2/8/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct ClassWizApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    init() {
        FirebaseApp.configure()

        // Enable Firestore offline persistence
        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings

        // Customize navigation bar appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environmentObject(appState)
                .onAppear {
                    appState.startListening()
                }
                .onReceive(networkMonitor.$isConnected) { connected in
                    appState.isOffline = !connected
                }
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
