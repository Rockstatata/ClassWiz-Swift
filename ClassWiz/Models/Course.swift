// Course.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct Course: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var code: String       // e.g. "CSE-321"
    var name: String       // e.g. "Database Systems"
    var credit: Double     // Credit hours
    var isActive: Bool     // Archived or not

    var displayName: String {
        "\(code) – \(name)"
    }
}

// MARK: - Assignment Models

struct Assignment: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var courseId: String
    var teacherId: String
    var title: String
    var description: String
    var dueDate: Date
    var createdAt: Date = Date()
}

struct AssignmentSubmission: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var assignmentId: String
    var studentId: String
    var documentURL: String?
    var imageURL: String?
    var submittedAt: Date = Date()
    var grade: String?
    var feedback: String?
}
