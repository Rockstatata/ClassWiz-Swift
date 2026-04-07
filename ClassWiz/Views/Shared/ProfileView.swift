// ProfileView.swift
// ClassWiz – Views/Shared

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSignOutConfirmation = false
    @State private var batchName: String?
    @State private var headerAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                // Subtle top gradient wash
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.08), AppTheme.background],
                    startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                            .opacity(headerAppeared ? 1 : 0)
                            .offset(y: headerAppeared ? 0 : -16)

                        accountSection
                        appearanceSection
                        syncSection
                        signOutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut(appState: appState)
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task { await loadBatchName() }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                    headerAppeared = true
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow
                Circle()
                    .fill(RadialGradient(
                        colors: [roleColor.opacity(0.35), .clear],
                        center: .center, startRadius: 20, endRadius: 60))
                    .frame(width: 120, height: 120)
                    .blur(radius: 14)

                Circle()
                    .fill(LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 16, y: 6)

                Text(appState.currentUser?.initials ?? "?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text(appState.currentUser?.name ?? "User")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(appState.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                // Role chip
                HStack(spacing: 5) {
                    Image(systemName: appState.currentUser?.role.icon ?? "person")
                        .font(.caption.weight(.semibold))
                    Text(appState.currentUser?.role.displayName ?? "")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(roleColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(roleColor.opacity(0.12))
                        .overlay(Capsule().stroke(roleColor.opacity(0.25), lineWidth: 1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(glassCard)
    }

    // MARK: - Account Info Section

    private var accountSection: some View {
        settingsSection(title: "Account") {
            settingsRow(icon: "person.fill", iconColor: AppTheme.primary, label: "Name",
                        value: appState.currentUser?.name ?? "—")
            settingsDivider
            settingsRow(icon: "envelope.fill", iconColor: AppTheme.secondary, label: "Email",
                        value: appState.currentUser?.email ?? "—")
            settingsDivider
            settingsRow(icon: "shield.fill", iconColor: roleColor, label: "Role",
                        value: appState.currentUser?.role.displayName ?? "—")

            if appState.currentUser?.role == .student {
                settingsDivider
                settingsRow(icon: "person.3.fill", iconColor: AppTheme.accent, label: "Batch",
                            value: batchName ?? appState.currentUser?.batchId ?? "—")
            }

            if let date = appState.currentUser?.createdAt {
                settingsDivider
                settingsRow(icon: "calendar", iconColor: .orange, label: "Member since",
                            value: date.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    // MARK: - Appearance Section (dark mode toggle)

    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            // System / Light / Dark three-way picker
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.indigo.opacity(0.14))
                            .frame(width: 32, height: 32)
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.indigo)
                    }
                    Text("Theme")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }

                HStack(spacing: 0) {
                    themeOption(label: "System", icon: "circle.lefthalf.filled", scheme: nil)
                    themeOption(label: "Light",  icon: "sun.max.fill",           scheme: .light)
                    themeOption(label: "Dark",   icon: "moon.stars.fill",         scheme: .dark)
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceSecondary))
            }
        }
    }

    private func themeOption(label: String, icon: String, scheme: ColorScheme?) -> some View {
        let isSelected = appState.preferredColorScheme == scheme
        return Button {
            withAnimation(AppTheme.defaultAnimation) {
                appState.preferredColorScheme = scheme
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? (scheme == .dark ? Color.indigo : AppTheme.primary) : AppTheme.textSecondary)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? AppTheme.surface : Color.clear)
                    .shadow(color: isSelected ? .black.opacity(0.08) : .clear, radius: 4, y: 2)
            )
        }
        .animation(AppTheme.quickAnimation, value: isSelected)
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        settingsSection(title: "Connection") {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((appState.isOffline ? AppTheme.warning : AppTheme.safe).opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: appState.isOffline ? "wifi.slash" : "wifi")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appState.isOffline ? AppTheme.warning : AppTheme.safe)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isOffline ? "Offline" : "Connected")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    if let lastSync = appState.lastSyncDate {
                        Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()

                Circle()
                    .fill(appState.isOffline ? AppTheme.warning : AppTheme.safe)
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Button {
            HapticManager.warning()
            showSignOutConfirmation = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.critical.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.critical)
                }
                Text("Sign Out")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.critical)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.critical.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.critical.opacity(0.18), lineWidth: 1))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }

    // MARK: - Reusable Building Blocks

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }

    private func settingsRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 10)
    }

    private var settingsDivider: some View {
        Divider().padding(.leading, 44)
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.divider, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    private var roleColor: Color {
        switch appState.currentUser?.role {
        case .student: return AppTheme.primary
        case .teacher: return AppTheme.secondary
        case .admin:   return AppTheme.accent
        case .none:    return AppTheme.textSecondary
        }
    }

    // MARK: - Helpers

    private func loadBatchName() async {
        guard let batchId = appState.currentUser?.batchId, !batchId.isEmpty else { return }
        do { batchName = try await BatchService.shared.fetchBatch(id: batchId).name } catch {}
    }
}

// MARK: - Previews

#Preview("Profile – Student") { ProfileView().environmentObject(MockData.makeStudentAppState()) }
#Preview("Profile – Teacher") { ProfileView().environmentObject(MockData.makeTeacherAppState()) }
#Preview("Profile – Dark")    { ProfileView().environmentObject(MockData.makeStudentAppState()).preferredColorScheme(.dark) }
