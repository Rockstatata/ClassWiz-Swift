// UserService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class UserService {
    static let shared = UserService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("users") }

    // MARK: - Fetch

    func fetchUser(userId: String) async throws -> AppUser {
        let doc = try await collection.document(userId).getDocument()
        guard doc.exists, let data = doc.data() else {
            throw ClassWizError.notFound("User")
        }
        return AppUser(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            role: UserRole(rawValue: data["role"] as? String ?? "student") ?? .student,
            batchId: data["batchId"] as? String,
            isApproved: data["isApproved"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
        )
    }

    func fetchAllUsers() async throws -> [AppUser] {
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.compactMap { self.mapUser($0) }
    }

    func fetchUsers(byRole role: UserRole) async throws -> [AppUser] {
        let snapshot = try await collection
            .whereField("role", isEqualTo: role.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { self.mapUser($0) }
    }

    func fetchStudents(inBatch batchId: String) async throws -> [AppUser] {
        let snapshot = try await collection
            .whereField("role", isEqualTo: "student")
            .whereField("batchId", isEqualTo: batchId)
            .getDocuments()
        return snapshot.documents.compactMap { self.mapUser($0) }
    }

    func fetchPendingApprovals() async throws -> [AppUser] {
        let snapshot = try await collection
            .whereField("isApproved", isEqualTo: false)
            .getDocuments()
        return snapshot.documents.compactMap { self.mapUser($0) }
    }

    private func mapUser(_ doc: QueryDocumentSnapshot) -> AppUser? {
        let data = doc.data()
        return AppUser(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            role: UserRole(rawValue: data["role"] as? String ?? "student") ?? .student,
            batchId: data["batchId"] as? String,
            isApproved: data["isApproved"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
        )
    }

    // MARK: - Create

    func createUser(_ user: AppUser) async throws {
        var userData: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "isApproved": user.isApproved,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let batchId = user.batchId {
            userData["batchId"] = batchId
        }
        try await collection.document(user.id).setData(userData)
    }

    // MARK: - Update

    func updateUser(_ user: AppUser) async throws {
        var userData: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "isApproved": user.isApproved
        ]
        if let batchId = user.batchId {
            userData["batchId"] = batchId
        }
        try await collection.document(user.id).updateData(userData)
    }

    // MARK: - Approval

    func approveUser(userId: String) async throws {
        try await collection.document(userId).updateData(["isApproved": true])
    }

    func rejectUser(userId: String) async throws {
        // Delete Firestore doc; caller should also delete the Auth user if needed
        try await collection.document(userId).delete()
    }

    // MARK: - Delete

    func deleteUser(userId: String) async throws {
        try await collection.document(userId).delete()
    }
}
