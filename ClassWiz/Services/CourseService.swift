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
}

// MARK: - Assignment Service

enum AssignmentError: Error {
    case documentNotFound
    case uploadFailed
}

final class AssignmentService {
    static let shared = AssignmentService()
    private let assignmentsRef = Firestore.firestore().collection("assignments")
    private let submissionsRef = Firestore.firestore().collection("assignmentSubmissions")

    // MARK: - Assignments (Teacher)

    func createAssignment(_ assignment: Assignment) async throws {
        _ = try assignmentsRef.addDocument(from: assignment)
    }

    func fetchAssignments(forCourse courseId: String) async throws -> [Assignment] {
        let snapshot = try await assignmentsRef
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Assignment.self) }
    }

    func fetchAssignments(forTeacher teacherId: String) async throws -> [Assignment] {
        let snapshot = try await assignmentsRef
            .whereField("teacherId", isEqualTo: teacherId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Assignment.self) }
    }

    // MARK: - Submissions (Student / Teacher)

    func submitAssignment(submission: AssignmentSubmission, fileURL: URL?) async throws {
        var mutableSubmission = submission

        // If file uploading were supported via Storage directly we would do it here. For now we will mock the URL.
        if let file = fileURL {
            mutableSubmission.documentURL = file.absoluteString
        }

        _ = try submissionsRef.addDocument(from: mutableSubmission)
    }

    func fetchSubmissions(forAssignment assignmentId: String) async throws -> [AssignmentSubmission] {
        let snapshot = try await submissionsRef
            .whereField("assignmentId", isEqualTo: assignmentId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AssignmentSubmission.self) }
    }

    func gradeSubmission(id: String, grade: String, feedback: String?) async throws {
        try await submissionsRef.document(id).updateData([
            "grade": grade,
            "feedback": feedback as Any
        ])
    }
}
