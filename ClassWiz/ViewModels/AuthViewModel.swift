// AuthViewModel.swift
// ClassWiz – ViewModels

import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Shared fields
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Sign-up only fields
    @Published var name = ""
    @Published var confirmPassword = ""
    @Published var selectedRole: UserRole = .student
    @Published var selectedBatchId: String = ""
    @Published var availableBatches: [Batch] = []

    // MARK: - Sign Up

    func signUp(appState: AppState) {
        guard validateSignUp() else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 1. Load batches if not already loaded (needed for validation)
                if availableBatches.isEmpty {
                    availableBatches = (try? await BatchService.shared.fetchAll()) ?? []
                }

                // 2. Create Firebase Auth account
                let userId = try await AuthService.shared.createUser(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )

                // 3. Write Firestore user doc — isApproved = false until admin approves
                //    Admins are auto-approved (they register via the admin toggle)
                let isAdmin = selectedRole == .admin
                let user = AppUser(
                    id: userId,
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    role: selectedRole,
                    batchId: selectedRole == .student ? (selectedBatchId.isEmpty ? nil : selectedBatchId) : nil,
                    isApproved: isAdmin,
                    createdAt: Date()
                )
                try await UserService.shared.createUser(user)

                // 4. AppState auth listener fires automatically, which calls resolveUser
                //    and routes to .pendingApproval or .signedIn based on isApproved.
                HapticManager.success()
            } catch {
                errorMessage = mapAuthError(error)
                showError = true
                HapticManager.error()
                // Sign out from Firebase if Firestore write failed so user isn't stuck
                try? AuthService.shared.signOut()
            }
            isLoading = false
        }
    }

    func loadBatches() {
        Task {
            availableBatches = (try? await BatchService.shared.fetchAll()) ?? []
        }
    }

    // MARK: - Sign In

    func signIn(appState: AppState) {
        guard validate() else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Firebase sign-in fires the auth state listener in AppState,
                // which resolves the user document and transitions authState automatically.
                _ = try await AuthService.shared.signIn(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                HapticManager.success()
            } catch {
                errorMessage = mapAuthError(error)
                showError = true
                HapticManager.error()
            }
            isLoading = false
        }
    }

    // MARK: - Sign Out

    func signOut(appState: AppState) {
        do {
            try AuthService.shared.signOut()
            // Auth listener in AppState will call appState.signOut() automatically,
            // but we clear form fields here immediately.
            email = ""; password = ""; name = ""; confirmPassword = ""
            HapticManager.mediumImpact()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Validation

    private func validateSignUp() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your full name."; showError = true; return false
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email address."; showError = true; return false
        }
        if password.isEmpty || password.count < 6 {
            errorMessage = "Password must be at least 6 characters."; showError = true; return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."; showError = true; return false
        }
        return true
    }

    private func validate() -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email address."
            showError = true
            return false
        }
        if password.isEmpty {
            errorMessage = "Please enter your password."
            showError = true
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            showError = true
            return false
        }
        return true
    }

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address format."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled."
        default:
            return "Authentication failed. Please try again."
        }
    }
}
