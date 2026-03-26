// TeacherAssignment.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct TeacherAssignment: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var teacherId: String
    var courseId: String
    var batchId: String
}
