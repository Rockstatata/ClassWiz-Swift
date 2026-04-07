// UserManagementView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

@MainActor
final class UserManagementViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedRole: UserRole?
    @Published var errorMessage: String?

    var filteredUsers: [AppUser] {
        var result = users

        if let role = selectedRole {
            result = result.filter { $0.role == role }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    func loadUsers() async {
        isLoading = true
        do {
            users = try await UserService.shared.fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteUser(_ user: AppUser) async {
        do {
            try await UserService.shared.deleteUser(userId: user.id)
            users.removeAll { $0.id == user.id }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}

struct UserManagementView: View {
    @StateObject private var viewModel = UserManagementViewModel()
    @State private var showCreateUser = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(AppTheme.primary)
            } else {
                VStack(spacing: 0) {
                    // Role filter
                    roleFilter

                    List {
                        ForEach(viewModel.filteredUsers) { user in
                            userRow(user)
                                .swipeActions(edge: .trailing) {
                                    if user.role != .admin {
                                        Button(role: .destructive) {
                                            Task { await viewModel.deleteUser(user) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $viewModel.searchText, prompt: "Search users...")
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateUser = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .sheet(isPresented: $showCreateUser) {
            NavigationStack {
                UserCreationView {
                    showCreateUser = false
                    Task { await viewModel.loadUsers() }
                }
            }
        }
        .refreshable {
            await viewModel.loadUsers()
        }
        .task {
            await viewModel.loadUsers()
        }
    }

    // MARK: - Role Filter

    private var roleFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                roleFilterPill(nil, label: "All")
                ForEach(UserRole.allCases) { role in
                    roleFilterPill(role, label: role.displayName)
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
    }

    private func roleFilterPill(_ role: UserRole?, label: String) -> some View {
        let isSelected = viewModel.selectedRole == role
        return Button {
            withAnimation(AppTheme.quickAnimation) {
                viewModel.selectedRole = role
            }
            HapticManager.selection()
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.primary : AppTheme.surfaceSecondary)
                )
        }
    }

    private func userRow(_ user: AppUser) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                Circle()
                    .fill(roleColor(user.role).opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: user.role.icon)
                    .font(.caption)
                    .foregroundColor(roleColor(user.role))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text(user.role.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(roleColor(user.role))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(roleColor(user.role).opacity(0.12))
                )
        }
        .padding(.vertical, 4)
    }

    private func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .student: return AppTheme.primary
        case .teacher: return AppTheme.secondary
        case .admin:   return AppTheme.accent
        }
    }
}

// MARK: - User Creation View

struct UserCreationView: View {
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .student
    @State private var selectedBatchId = ""
    @State private var batches: [Batch] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section("User Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password (min 6 characters)", text: $password)
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Label(role.displayName, systemImage: role.icon).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if selectedRole == .student {
                    Section("Batch") {
                        Picker("Batch", selection: $selectedBatchId) {
                            Text("Select Batch").tag("")
                            ForEach(batches) { batch in
                                Text(batch.name).tag(batch.id ?? "")
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(AppTheme.critical).font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await createUser() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView().tint(.white) }
                            Text("Create Account").font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(isSaving || name.isEmpty || email.isEmpty || password.count < 6)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Create User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .task {
            do {
                batches = try await BatchService.shared.fetchAll()
            } catch { /* silent */ }
        }
    }

    private func createUser() async {
        isSaving = true
        errorMessage = nil

        do {
            let userId = try await AuthService.shared.createUser(email: email.trimmingCharacters(in: .whitespaces), password: password)

            let user = AppUser(
                id: userId,
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                role: selectedRole,
                batchId: selectedRole == .student ? (selectedBatchId.isEmpty ? nil : selectedBatchId) : nil,
                isApproved: true,  // Admin-created accounts are pre-approved
                createdAt: Date()
            )

            try await UserService.shared.createUser(user)

            HapticManager.success()
            onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }

        isSaving = false
    }
}
