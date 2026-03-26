// AttendanceRecord.swift
// ClassWiz – Models

import Foundation
import SwiftUI
import FirebaseFirestore

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "present"
    case absent  = "absent"

    var icon: String {
        switch self {
        case .present: return "checkmark.circle.fill"
        case .absent:  return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .present: return AppTheme.safe
        case .absent:  return AppTheme.critical
        }
    }
}

struct AttendanceRecord: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var studentId: String
    var courseId: String
    var date: Date
    var status: AttendanceStatus
    var markedBy: String  // Teacher userId

    var dateString: String {
        DateFormatters.mediumDate.string(from: date)
    }
}
