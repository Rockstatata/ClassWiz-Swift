// NotificationService.swift
// ClassWiz – Services

import FirebaseFirestore

final class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("notifications")
    
    private init() {}
    
    func fetchNotifications(for userId: String) async throws -> [CWNotification] {
        let snapshot = try await collectionRef
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
            
        return snapshot.documents.compactMap { try? $0.data(as: CWNotification.self) }
    }
    
    func markAsRead(notificationId: String) async throws {
        try await collectionRef.document(notificationId).updateData(["isRead": true])
    }
    
    func markAllAsRead(for userId: String) async throws {
        let snapshot = try await collectionRef
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
            
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }
    
    func createNotification(receiverId: String, title: String, message: String, icon: String = "bell.fill") async throws {
        let notif = CWNotification(
            receiverId: receiverId,
            title: title,
            message: message,
            icon: icon,
            createdAt: Date(),
            isRead: false
        )
        try collectionRef.addDocument(from: notif)
    }
}
