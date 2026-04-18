// CWNotification.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct CWNotification: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let receiverId: String
    let title: String
    let message: String
    let icon: String
    let createdAt: Date
    var isRead: Bool
}
