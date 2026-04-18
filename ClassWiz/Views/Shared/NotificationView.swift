// NotificationView.swift
// ClassWiz – Views/Shared

import SwiftUI
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [CWNotification] = []
    @Published var isLoading = false
    
    func loadNotifications(userId: String) async {
        isLoading = true
        do {
            let fetched = try await NotificationService.shared.fetchNotifications(for: userId)
            self.notifications = fetched
        } catch {
            print("Error parsing notifications: \(error)")
        }
        isLoading = false
    }
    
    func markAllAsRead(userId: String) async {
        do {
            try await NotificationService.shared.markAllAsRead(for: userId)
            for i in notifications.indices {
                notifications[i].isRead = true
            }
        } catch { }
    }
}

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ClassWizScreen(title: "Notifications", subtitle: "Stay updated", showNotification: false, showProfile: false, showBackButton: true, scrollable: true) {
            VStack(spacing: AppTheme.spacingMD) {
                if !viewModel.notifications.isEmpty {
                    HStack {
                        Spacer()
                        Button("Mark all as read") {
                            guard let userId = appState.currentUser?.id else { return }
                            Task {
                                await viewModel.markAllAsRead(userId: userId)
                                HapticManager.lightImpact()
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, AppTheme.spacingMD)
                }
                
                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                        .padding(.top, 40)
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Notifications",
                        subtitle: "You're all caught up!"
                    )
                } else {
                    ForEach(viewModel.notifications) { notification in
                        notificationCard(notification)
                            .padding(.horizontal, AppTheme.spacingMD)
                    }
                }
            }
            .padding(.bottom, AppTheme.spacingMD)
        }
        .task {
            if let user = appState.currentUser {
                await viewModel.loadNotifications(userId: user.id)
            }
        }
    }
    
    private func notificationCard(_ notification: CWNotification) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? AppTheme.surfaceSecondary : AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: notification.icon)
                    .font(.title3)
                    .foregroundColor(notification.isRead ? AppTheme.textSecondary : AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(notification.isRead ? AppTheme.textPrimary : AppTheme.primary)
                    Spacer()
                    Text(timeAgo(from: notification.createdAt))
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(notification.isRead ? Color.clear : AppTheme.primary.opacity(0.3), lineWidth: 1)
        )
        .opacity(notification.isRead ? 0.8 : 1.0)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationView()
        .environmentObject(MockData.makeStudentAppState())
}
