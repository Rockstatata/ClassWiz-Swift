// PendingApprovalsView.swift
// ClassWiz – Views/Admin
//
// Allows admins to review, approve, or reject newly registered users.

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class PendingApprovalsViewModel: ObservableObject {
    @Published var pendingUsers: [AppUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var processingIds: Set<String> = []

    func loadPending() async {
        isLoading = true
        errorMessage = nil
        do {
            pendingUsers = try await UserService.shared.fetchPendingApprovals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approve(_ user: AppUser) async {
        processingIds.insert(user.id)
        do {
            try await UserService.shared.approveUser(userId: user.id)
            withAnimation(AppTheme.defaultAnimation) {
                pendingUsers.removeAll { $0.id == user.id }
            }
            toastMessage = "\(user.name) approved ✓"
            HapticManager.success()
        } catch {
            errorMessage = "Failed to approve: \(error.localizedDescription)"
            HapticManager.error()
        }
        processingIds.remove(user.id)
    }

    func reject(_ user: AppUser) async {
        processingIds.insert(user.id)
        do {
            try await UserService.shared.rejectUser(userId: user.id)
            withAnimation(AppTheme.defaultAnimation) {
                pendingUsers.removeAll { $0.id == user.id }
            }
            toastMessage = "\(user.name) rejected"
            HapticManager.warning()
        } catch {
            errorMessage = "Failed to reject: \(error.localizedDescription)"
            HapticManager.error()
        }
        processingIds.remove(user.id)
    }
}

// MARK: - View

struct PendingApprovalsView: View {
    @StateObject private var viewModel = PendingApprovalsViewModel()
    @State private var showToast = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.pendingUsers.isEmpty {
                    emptyState
                } else {
                    pendingList
                }
            }

            // Toast
            if showToast, let msg = viewModel.toastMessage {
                toastView(msg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("Pending Approvals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadPending() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.toastMessage) { _, msg in
            guard msg != nil else { return }
            withAnimation(AppTheme.quickAnimation) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(AppTheme.quickAnimation) { showToast = false }
                viewModel.toastMessage = nil
            }
        }
        .task { await viewModel.loadPending() }
        .refreshable { await viewModel.loadPending() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppTheme.spacingMD) {
            ProgressView().tint(AppTheme.primary)
            Text("Loading pending approvals…")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.safe, AppTheme.primary.opacity(0.3))

            Text("All Caught Up!")
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("No accounts are waiting for approval.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.spacingXL)
    }

    // MARK: - List

    private var pendingList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMD) {
                // Header count
                HStack {
                    Image(systemName: "person.badge.clock.fill")
                        .foregroundColor(AppTheme.warning)
                    Text("\(viewModel.pendingUsers.count) account\(viewModel.pendingUsers.count == 1 ? "" : "s") awaiting approval")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.top, AppTheme.spacingSM)

                ForEach(viewModel.pendingUsers) { user in
                    pendingUserCard(user)
                        .padding(.horizontal, AppTheme.spacingMD)
                }
            }
            .padding(.bottom, AppTheme.spacingXXL)
        }
    }

    // MARK: - Pending User Card

    private func pendingUserCard(_ user: AppUser) -> some View {
        let isProcessing = viewModel.processingIds.contains(user.id)

        return VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            // User header
            HStack(spacing: AppTheme.spacingMD) {
                ZStack {
                    Circle()
                        .fill(roleColor(user.role).opacity(0.14))
                        .frame(width: 48, height: 48)
                    Text(user.initials)
                        .font(.headline.weight(.bold))
                        .foregroundColor(roleColor(user.role))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 5) {
                        Image(systemName: user.role.icon)
                            .font(.caption2)
                        Text(user.role.displayName)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(roleColor(user.role))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(roleColor(user.role).opacity(0.10))
                    )
                }

                Spacer()

                // Pending badge
                Text("Pending")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(AppTheme.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.warning.opacity(0.12)))
            }

            // Batch row (students)
            if let batchId = user.batchId, !batchId.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Batch: \(batchId)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Joined date
            if let date = user.createdAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Registered \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Divider()

            // Action buttons
            HStack(spacing: AppTheme.spacingMD) {
                // Reject
                Button {
                    Task { await viewModel.reject(user) }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(AppTheme.critical)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                            .fill(AppTheme.critical.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                                    .stroke(AppTheme.critical.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .disabled(isProcessing)

                // Approve
                Button {
                    Task { await viewModel.approve(user) }
                } label: {
                    HStack(spacing: 5) {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Approve")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                            .fill(AppTheme.safe)
                    )
                }
                .disabled(isProcessing)
            }
        }
        .padding(AppTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .opacity(isProcessing ? 0.6 : 1.0)
        .animation(AppTheme.quickAnimation, value: isProcessing)
    }

    // MARK: - Toast

    private func toastView(_ message: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM + 2)
        .background(
            Capsule()
                .fill(AppTheme.primary)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 4)
        )
    }

    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .student: return AppTheme.primary
        case .teacher: return AppTheme.secondary
        case .admin:   return AppTheme.accent
        }
    }
}

// MARK: - Previews

#Preview("Pending Approvals") {
    NavigationStack {
        PendingApprovalsView()
    }
    .environmentObject(MockData.makeAdminAppState())
}
