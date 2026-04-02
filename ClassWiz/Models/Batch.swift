// Batch.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct Batch: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String          // e.g. "CSE 3A"
    var semesterId: String    // Academic semester
    var year: Int             // Academic year

    var displayName: String {
        "\(name) (\(year))"
    }
}
