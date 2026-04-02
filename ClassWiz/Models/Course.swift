// Course.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct Course: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var code: String       // e.g. "CSE-321"
    var name: String       // e.g. "Database Systems"
    var credit: Int        // Credit hours
    var isActive: Bool     // Archived or not

    var displayName: String {
        "\(code) – \(name)"
    }
}
