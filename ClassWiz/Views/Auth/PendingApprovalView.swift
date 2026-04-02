// PendingApprovalView.swift
// ClassWiz – Views/Auth
//
// Shown when a user has registered but their account hasn't been
// approved by an admin yet.

import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isRefreshing = false
    @State private var showSignOutAlert = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            LinearGradient(
                colors: [AppTheme.warning.opacity(0.06), AppTheme.background, AppTheme.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.spacingXL) {
                    Spacer().frame(height: AppTheme.spacingXL)

                    // MARK: Illustration
                    illustrationSection

                    // MARK: Text
                    textSection

                    // MARK: Info Card
                    infoCard

                    // MARK: Actions
                    actionButtons

                    Spacer().frame(height: AppTheme.spacingMD)

                    // Footer
                    Text("Logged in as \(appState.currentUser?.email ?? "")")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.bottom, AppTheme.spacingMD)
                }
                .padding(.horizontal, AppTheme.spacingLG)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut(appState: appState)
            }
        } message: {
            Text("You can sign back in once your account is approved.")
        }
    }

    // MARK: - Illustration

    private var illustrationSection: some View {
        ZStack {
            Circle()
                .fill(AppTheme.warning.opacity(0.10))
                .frame(width: 130, height: 130)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .onAppear { pulseScale = 1.12 }

            Circle()
                .fill(AppTheme.warning.opacity(0.18))
                .frame(width: 100, height: 100)

            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.warning, AppTheme.primary)
        }
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(spacing: AppTheme.spacingSM) {
            Text("Awaiting Approval")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Text("Hi \(appState.currentUser?.name.components(separatedBy: " ").first ?? "there")! Your account has been created successfully.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("An administrator needs to approve your account before you can access ClassWiz.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "person.fill",
                iconColor: AppTheme.primary,
                label: "Name",
                value: appState.currentUser?.name ?? "—"
            )
            Divider().padding(.leading, 52)
            infoRow(
                icon: roleIcon,
                iconColor: roleColor,
                label: "Role",
                value: appState.currentUser?.role.displayName ?? "—"
            )
            if let batchId = appState.currentUser?.batchId, !batchId.isEmpty {
                Divider().padding(.leading, 52)
                infoRow(
                    icon: "person.3.fill",
                    iconColor: AppTheme.secondary,
                    label: "Batch",
                    value: batchId
                )
            }
            Divider().padding(.leading, 52)
            infoRow(
                icon: "checkmark.seal.fill",
                iconColor: AppTheme.warning,
                label: "Status",
                value: "Pending Admin Approval"
            )
        }
        .cwCard()
    }

    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
            }

            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, AppTheme.spacingSM)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.spacingMD) {
            // Refresh / Check status button
            Button {
                checkApprovalStatus()
            } label: {
                HStack(spacing: 8) {
                    if isRefreshing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isRefreshing ? "Checking…" : "Check Approval Status")
                }
            }
            .buttonStyle(CWPrimaryButtonStyle(isLoading: isRefreshing))
            .disabled(isRefreshing)

            // Sign Out
            Button {
                showSignOutAlert = true
            } label: {
                Text("Sign Out")
            }
            .buttonStyle(CWSecondaryButtonStyle())
        }
    }

    // MARK: - Helpers

    private var roleIcon: String { appState.currentUser?.role.icon ?? "person" }
    private var roleColor: Color {
        switch appState.currentUser?.role {
        case .student: return AppTheme.primary
        case .teacher: return AppTheme.secondary
        case .admin:   return AppTheme.accent
        case .none:    return AppTheme.textSecondary
        }
    }

    private func checkApprovalStatus() {
        guard let userId = appState.currentUser?.id else { return }
        isRefreshing = true
        HapticManager.lightImpact()

        Task {
            do {
                let user = try await UserService.shared.fetchUser(userId: userId)
                if user.isApproved {
                    // Transition to the main app — update appState
                    appState.signIn(user: user)
                    HapticManager.success()
                } else {
                    HapticManager.lightImpact()
                }
            } catch {
                // Silent — user stays on this screen
            }
            isRefreshing = false
        }
    }
}

// MARK: - Previews

#Preview("Pending Approval") {
    PendingApprovalView()
        .environmentObject({
            let s = AppState()
            s.setPendingApproval(user: AppUser(
                id: "uid", name: "Aryan Islam",
                email: "aryan@uni.edu", role: .student,
                batchId: "CSE 3A", isApproved: false
            ))
            return s
        }())
}
