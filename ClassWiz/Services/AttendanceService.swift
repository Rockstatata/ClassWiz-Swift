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
            .getDocuments()
        let records = snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
        return records.sorted { $0.date > $1.date }
    }

    func fetchAttendance(studentId: String, courseId: String) async throws -> [AttendanceRecord] {
        let snapshot = try await collection
            .whereField("studentId", isEqualTo: studentId)
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments()
        let records = snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
        return records.sorted { $0.date > $1.date }
    }

    // MARK: - Fetch for Teacher (by course + date)

    func fetchAttendance(courseId: String, date: Date) async throws -> [AttendanceRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // To avoid composite indexes, fetch by courseId then filter locally
        let snapshot = try await collection
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments()
        let records = snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
        return records.filter { $0.date >= startOfDay && $0.date < endOfDay }
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
    
    func markStudent(studentId: String, courseId: String, teacherId: String, date: Date, status: AttendanceStatus) async throws {
        let record = AttendanceRecord(
            studentId: studentId,
            courseId: courseId,
            date: date,
            status: status,
            markedBy: teacherId
        )
        // Store one record per student/course/day to keep it simple
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: date)
        let docId = "\(studentId)_\(courseId)_\(dateStr)"
        
        try collection.document(docId).setData(from: record)
    }
}

// MARK: - Automated Attendance Service
final class AutomatedAttendanceService {
    static let shared = AutomatedAttendanceService()
    private let sessionsRef = Firestore.firestore().collection("automatedAttendanceSessions")
    
    // Teacher creates an active session
    func startSession(routineId: String, teacherId: String, courseId: String, batchId: String, durationByMinutes: Int) async throws -> AttendanceSession {
        // Find existing to deactivate
        let existing = try await sessionsRef.whereField("routineId", isEqualTo: routineId).whereField("isActive", isEqualTo: true).getDocuments()
        for doc in existing.documents {
            try await doc.reference.updateData(["isActive": false])
        }

        let code = String(format: "%04d", Int.random(in: 1000...9999))
        let expiresAt = Calendar.current.date(byAdding: .minute, value: durationByMinutes, to: Date()) ?? Date()
        
        let session = AttendanceSession(
            routineId: routineId,
            teacherId: teacherId,
            courseId: courseId,
            batchId: batchId,
            secretCode: code,
            expiresAt: expiresAt,
            isActive: true
        )
        
        let ref = try sessionsRef.addDocument(from: session)
        var updatedSession = session
        updatedSession.id = ref.documentID
        return updatedSession
    }
    
    func endSession(sessionId: String) async throws {
        guard !sessionId.isEmpty else { return }
        try await sessionsRef.document(sessionId).updateData(["isActive": false])
    }
    
    func fetchActiveSession(forBatch batchId: String) async throws -> AttendanceSession? {
        let snapshot = try await sessionsRef
            .whereField("batchId", isEqualTo: batchId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let docs = snapshot.documents.compactMap { try? $0.data(as: AttendanceSession.self) }
        return docs.reversed().first(where: { $0.expiresAt > Date() }) // latest active unexpired
    }
    
    func submitCode(sessionId: String, code: String, studentId: String, courseId: String) async throws -> Bool {
        let snapshot = try await sessionsRef.document(sessionId).getDocument()
        guard let session = try? snapshot.data(as: AttendanceSession.self), session.isActive, session.expiresAt > Date() else {
            return false
        }
        
        if session.secretCode == code {
            try await AttendanceService.shared.markStudent(
                studentId: studentId,
                courseId: courseId,
                teacherId: session.teacherId,
                date: Date(),
                status: .present
            )
            return true
        }
        
        return false
    }
}
