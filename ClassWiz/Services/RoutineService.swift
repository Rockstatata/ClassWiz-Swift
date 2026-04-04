// RoutineService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class RoutineService {
    static let shared = RoutineService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("routines") }

    // MARK: - Fetch

    func fetchAll() async throws -> [Routine] {
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Routine.self) }
    }

    func fetchRoutines(forBatch batchId: String) async throws -> [Routine] {
        let snapshot = try await collection
            .whereField("batchId", isEqualTo: batchId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Routine.self) }
    }

    func fetchRoutines(forTeacher teacherId: String) async throws -> [Routine] {
        let snapshot = try await collection
            .whereField("teacherId", isEqualTo: teacherId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Routine.self) }
    }

    func fetchRoutines(forBatch batchId: String, day: Weekday) async throws -> [Routine] {
        let snapshot = try await collection
            .whereField("batchId", isEqualTo: batchId)
            .whereField("day", isEqualTo: day.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Routine.self) }
    }

    // MARK: - Create

    func create(_ routine: Routine) async throws -> String {
        let ref = try collection.addDocument(from: routine)
        return ref.documentID
    }

    // MARK: - Update

    func update(_ routine: Routine) async throws {
        guard let id = routine.id else { throw ClassWizError.validationFailed("Routine ID missing") }
        try collection.document(id).setData(from: routine)
    }

    // MARK: - Delete

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }

    // MARK: - Conflict Detection

    func checkConflict(day: Weekday, startTime: String, endTime: String, room: String, excludeId: String? = nil) async throws -> Bool {
        let snapshot = try await collection
            .whereField("day", isEqualTo: day.rawValue)
            .whereField("room", isEqualTo: room)
            .getDocuments()

        let routines = snapshot.documents.compactMap { try? $0.data(as: Routine.self) }
        return routines.contains { routine in
            if let excludeId, routine.id == excludeId { return false }
            // Overlapping time check
            return startTime < routine.endTime && endTime > routine.startTime
        }
    }
}
