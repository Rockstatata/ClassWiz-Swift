// AnalyticsRecord.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

struct AnalyticsRecord: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var courseId: String
    var attendancePercent: Double
    var riskLevel: String   // "safe" / "warning" / "critical"
    var totalClasses: Int
    var presentCount: Int
    var absentCount: Int

    var risk: RiskLevel {
        RiskLevel(rawValue: riskLevel) ?? .critical
    }
}

// MARK: - Course Attendance Stat (display model, not stored)

struct CourseAttendanceStat: Identifiable, Equatable {
    let id: String  // courseId
    let course: Course
    let totalClasses: Int
    let presentCount: Int
    let absentCount: Int
    let percentage: Double
    let risk: RiskLevel

    var classesNeededFor75: Int {
        guard percentage < 75 else { return 0 }
        // Present / (Total + X) >= 0.75  →  X = (present - 0.75*total) / (0.75 - 1) but simplified:
        // Need: (presentCount + X) / (totalClasses + X) >= 0.75
        // presentCount + X >= 0.75 * totalClasses + 0.75 * X
        // 0.25 * X >= 0.75 * totalClasses - presentCount
        // X >= (0.75 * totalClasses - presentCount) / 0.25
        let needed = Int(ceil((0.75 * Double(totalClasses) - Double(presentCount)) / 0.25))
        return max(needed, 0)
    }

    var maxAllowedAbsences: Int {
        guard percentage >= 75 else { return 0 }
        // (presentCount) / (totalClasses + X) >= 0.75
        // presentCount >= 0.75 * totalClasses + 0.75 * X
        // 0.75 * X <= presentCount - 0.75 * totalClasses
        // X <= (presentCount - 0.75 * totalClasses) / 0.75
        let allowed = Int(floor((Double(presentCount) - 0.75 * Double(totalClasses)) / 0.75))
        return max(allowed, 0)
    }
}
