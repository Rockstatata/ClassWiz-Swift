// BatchService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class BatchService {
    static let shared = BatchService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("batches") }

    // MARK: - Fetch

    func fetchAll() async throws -> [Batch] {
        let snapshot = try await collection.order(by: "year", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Batch.self) }
    }

    func fetchBatch(id: String) async throws -> Batch {
        let doc = try await collection.document(id).getDocument()
        guard let batch = try? doc.data(as: Batch.self) else {
            throw ClassWizError.notFound("Batch")
        }
        return batch
    }

    // MARK: - Create

    func create(_ batch: Batch) async throws -> String {
        let ref = try collection.addDocument(from: batch)
        return ref.documentID
    }

    // MARK: - Update

    func update(_ batch: Batch) async throws {
        guard let id = batch.id else { throw ClassWizError.validationFailed("Batch ID missing") }
        try collection.document(id).setData(from: batch)
    }

    // MARK: - Delete

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }
}
