// CourseService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class CourseService {
    static let shared = CourseService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("courses") }

    // MARK: - Fetch

    func fetchAll() async throws -> [Course] {
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Course.self) }
    }

    func fetchActive() async throws -> [Course] {
        let snapshot = try await collection
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Course.self) }
    }

    func fetchCourse(id: String) async throws -> Course {
        let doc = try await collection.document(id).getDocument()
        guard let course = try? doc.data(as: Course.self) else {
            throw ClassWizError.notFound("Course")
        }
        return course
    }

    // MARK: - Create

    func create(_ course: Course) async throws -> String {
        let ref = try collection.addDocument(from: course)
        return ref.documentID
    }

    // MARK: - Update

    func update(_ course: Course) async throws {
        guard let id = course.id else { throw ClassWizError.validationFailed("Course ID missing") }
        try collection.document(id).setData(from: course)
    }

    // MARK: - Delete / Archive

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }

    func toggleActive(id: String, isActive: Bool) async throws {
        try await collection.document(id).updateData(["isActive": isActive])
    }
}
