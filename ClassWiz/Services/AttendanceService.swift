// AttendanceService.swift
// ClassWiz – Services

import Foundation
import FirebaseFirestore

final class AttendanceService {
    static let shared = AttendanceService()
    private init() {}

    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("attendance") }

    // MARK: - Fetch for Student

    func fetchAttendance(studentId: String) async throws -> [AttendanceRecord] {
        let snapshot = try await collection
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }

    func fetchAttendance(studentId: String, courseId: String) async throws -> [AttendanceRecord] {
        let snapshot = try await collection
            .whereField("studentId", isEqualTo: studentId)
            .whereField("courseId", isEqualTo: courseId)
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }

    // MARK: - Fetch for Teacher (by course + date)

    func fetchAttendance(courseId: String, date: Date) async throws -> [AttendanceRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let snapshot = try await collection
            .whereField("courseId", isEqualTo: courseId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }

    func fetchAttendance(courseId: String, batchId: String, date: Date) async throws -> [AttendanceRecord] {
        // First get students in the batch, then filter
        let records = try await fetchAttendance(courseId: courseId, date: date)
        let students = try await UserService.shared.fetchStudents(inBatch: batchId)
        let studentIds = Set(students.map(\.id))
        return records.filter { studentIds.contains($0.studentId) }
    }

    // MARK: - Fetch all for a course (analytics)

    func fetchAllAttendance(courseId: String) async throws -> [AttendanceRecord] {
        let snapshot = try await collection
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }

    // MARK: - Fetch for leaderboard (batch + course)

    func fetchAttendance(batchId: String, courseId: String) async throws -> [AttendanceRecord] {
        let students = try await UserService.shared.fetchStudents(inBatch: batchId)
        let studentIds = students.map(\.id)

        guard !studentIds.isEmpty else { return [] }

        var allRecords: [AttendanceRecord] = []
        // Firestore 'in' queries limited to 30 items
        for chunk in stride(from: 0, to: studentIds.count, by: 30) {
            let end = min(chunk + 30, studentIds.count)
            let ids: [String] = Array(studentIds[chunk..<end])
            let snapshot = try await collection
                .whereField("courseId", isEqualTo: courseId)
                .whereField("studentId", in: ids)
                .getDocuments()
            let records = snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
            allRecords.append(contentsOf: records)
        }
        return allRecords
    }

    // MARK: - Mark Attendance (Batch)

    func markAttendance(records: [AttendanceRecord]) async throws {
        let batch = db.batch()
        for record in records {
            let ref = collection.document()
            try batch.setData(from: record, forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: - Mark Single

    func markAttendance(_ record: AttendanceRecord) async throws -> String {
        let ref = try collection.addDocument(from: record)
        return ref.documentID
    }

    // MARK: - Update (edit window)

    func updateAttendance(_ record: AttendanceRecord) async throws {
        guard let id = record.id else { throw ClassWizError.validationFailed("Attendance ID missing") }
        try collection.document(id).setData(from: record)
    }

    // MARK: - Delete

    func deleteAttendance(id: String) async throws {
        try await collection.document(id).delete()
    }

    // MARK: - Edit Window Check (24 hours)

    static func isWithinEditWindow(recordDate: Date, windowHours: Int = 24) -> Bool {
        let now = Date()
        let elapsed = now.timeIntervalSince(recordDate)
        return elapsed < Double(windowHours) * 3600
    }
}
