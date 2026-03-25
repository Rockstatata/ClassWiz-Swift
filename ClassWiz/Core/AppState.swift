// AppState.swift
// ClassWiz – Core

import SwiftUI
import Combine
import FirebaseAuth

// MARK: - Auth State

enum AuthState: Equatable {
    case loading
    case signedOut
    case pendingApproval   // signed in with Firebase but not yet approved by admin
    case signedIn(UserRole)
}

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case teacher
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: return "Student"
        case .teacher: return "Teacher"
        case .admin:   return "Admin"
        }
    }

    var icon: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .teacher: return "person.crop.rectangle.fill"
        case .admin:   return "shield.fill"
        }
    }
}

// MARK: - App User (lightweight model for shared state)

struct AppUser: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var role: UserRole
    var batchId: String?
    var isApproved: Bool = false
    var createdAt: Date?

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - App State (shared environment object)

@MainActor
final class AppState: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: AppUser?
    @Published var isOffline: Bool = false
    @Published var lastSyncDate: Date?
    @Published var toastMessage: ToastMessage?

    // MARK: - Appearance preference (persisted)
    @Published var preferredColorScheme: ColorScheme? {
        didSet {
            if let scheme = preferredColorScheme {
                UserDefaults.standard.set(scheme == .dark ? "dark" : "light", forKey: "cwColorScheme")
            } else {
                UserDefaults.standard.removeObject(forKey: "cwColorScheme")
            }
        }
    }

    init() {
        // Restore persisted color scheme preference
        switch UserDefaults.standard.string(forKey: "cwColorScheme") {
        case "dark":  preferredColorScheme = .dark
        case "light": preferredColorScheme = .light
        default:      preferredColorScheme = nil
        }
    }

    private var authHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Auth Listener

    /// Call once at app launch. Subscribes to Firebase auth changes and
    /// transitions authState out of .loading as soon as Firebase responds.
    func startListening() {
        guard authHandle == nil else { return }
        authHandle = AuthService.shared.addStateListener { [weak self] userId in
            Task { @MainActor in
                guard let self else { return }
                if let userId {
                    await self.resolveUser(userId: userId)
                } else {
                    self.signOut()
                }
            }
        }
    }

    func stopListening() {
        if let handle = authHandle {
            AuthService.shared.removeStateListener(handle)
            authHandle = nil
        }
    }

    // MARK: - Sign In / Sign Out

    func signIn(user: AppUser) {
        currentUser = user
        authState = user.isApproved ? .signedIn(user.role) : .pendingApproval
        lastSyncDate = Date()
    }

    func setPendingApproval(user: AppUser) {
        currentUser = user
        authState = .pendingApproval
    }

    func signOut() {
        currentUser = nil
        authState = .signedOut
    }

    // MARK: - Private helpers

    private func resolveUser(userId: String) async {
        do {
            let user = try await UserService.shared.fetchUser(userId: userId)
            signIn(user: user)
        } catch {
            // Firestore document missing – treat as signed-out so LoginView appears
            signOut()
        }
    }
}

// MARK: - Toast Message

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType

    enum ToastType: Equatable {
        case success
        case error
        case info
    }
}
