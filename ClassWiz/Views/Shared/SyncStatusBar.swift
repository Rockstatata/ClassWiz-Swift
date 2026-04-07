// SyncStatusBar.swift
// ClassWiz

import SwiftUI

struct SyncStatusBar: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Circle()
                .fill(appState.isOffline ? AppTheme.warning : AppTheme.safe)
                .frame(width: 6, height: 6)

            if let lastSync = appState.lastSyncDate {
                Text("Synced \(DateFormatters.relativeString(from: lastSync))")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                Text(appState.isOffline ? "Offline" : "Connected")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}
