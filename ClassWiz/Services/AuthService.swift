// AuthService.swift
// ClassWiz – Services

import Foundation
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> String {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user.uid
    }

    // MARK: - Create User (admin use)

    func createUser(email: String, password: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user.uid
    }

    // MARK: - Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Current User

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    var isSignedIn: Bool {
        auth.currentUser != nil
    }

    // MARK: - Auth State Listener

    func addStateListener(_ callback: @escaping (String?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            callback(user?.uid)
        }
    }

    func removeStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
