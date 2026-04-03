// Routine.swift
// ClassWiz – Models

import Foundation
import FirebaseFirestore

enum Weekday: String, Codable, CaseIterable, Identifiable, Comparable {
    case sunday    = "Sunday"
    case monday    = "Monday"
    case tuesday   = "Tuesday"
    case wednesday = "Wednesday"
    case thursday  = "Thursday"
    case friday    = "Friday"
    case saturday  = "Saturday"

    var id: String { rawValue }

    var shortName: String {
        String(rawValue.prefix(3))
    }

    var initial: String {
        String(rawValue.prefix(1))
    }

    private var sortOrder: Int {
        switch self {
        case .sunday:    return 0
        case .monday:    return 1
        case .tuesday:   return 2
        case .wednesday: return 3
        case .thursday:  return 4
        case .friday:    return 5
        case .saturday:  return 6
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    static var workdays: [Weekday] {
        [.sunday, .monday, .tuesday, .wednesday, .thursday]
    }

    static var today: Weekday {
        let dayIndex = Calendar.current.component(.weekday, from: Date())
        switch dayIndex {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}

struct Routine: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var courseId: String
    var teacherId: String
    var batchId: String
    var day: Weekday
    var startTime: String  // "09:00"
    var endTime: String    // "10:30"
    var room: String

    var timeSlot: String {
        "\(DateFormatters.formatTime(startTime)) – \(DateFormatters.formatTime(endTime))"
    }

    var isCurrentlyActive: Bool {
        guard day == Weekday.today else { return false }
        let now = DateFormatters.time24.string(from: Date())
        return now >= startTime && now <= endTime
    }
}
