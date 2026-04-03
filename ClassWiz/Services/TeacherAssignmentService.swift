// TeacherAssignmentService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class TeacherAssignmentService {
    static let shared = TeacherAssignmentService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("teacherAssignments") }

    // MARK: - Fetch

    func fetchAll() async throws -> [TeacherAssignment] {
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TeacherAssignment.self) }
    }

    func fetchAssignments(forTeacher teacherId: String) async throws -> [TeacherAssignment] {
        let snapshot = try await collection
            .whereField("teacherId", isEqualTo: teacherId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TeacherAssignment.self) }
    }

    func fetchAssignments(forCourse courseId: String) async throws -> [TeacherAssignment] {
        let snapshot = try await collection
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TeacherAssignment.self) }
    }

    func fetchAssignments(forBatch batchId: String) async throws -> [TeacherAssignment] {
        let snapshot = try await collection
            .whereField("batchId", isEqualTo: batchId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TeacherAssignment.self) }
    }

    // MARK: - Create

    func create(_ assignment: TeacherAssignment) async throws -> String {
        let ref = try collection.addDocument(from: assignment)
        return ref.documentID
    }

    // MARK: - Update

    func update(_ assignment: TeacherAssignment) async throws {
        guard let id = assignment.id else { throw ClassWizError.validationFailed("Assignment ID missing") }
        try collection.document(id).setData(from: assignment)
    }

    // MARK: - Delete

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }

    // MARK: - Check if teacher is assigned

    func isTeacherAssigned(teacherId: String, courseId: String, batchId: String) async throws -> Bool {
        let snapshot = try await collection
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("courseId", isEqualTo: courseId)
            .whereField("batchId", isEqualTo: batchId)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }
}
