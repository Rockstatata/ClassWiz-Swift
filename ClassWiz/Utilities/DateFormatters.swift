// DateFormatters.swift
// ClassWiz

import Foundation

enum DateFormatters {
    // MARK: - Shared Formatters (avoid repeated allocation)

    /// "Feb 28, 2026"
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// "09:00 AM"
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f
    }()

    /// "09:00"
    static let time24: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "Monday"
    static let dayName: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    /// "Feb 28"
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// "2026-02-28"
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Relative: "5 min ago", "yesterday"
    static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    // MARK: - Helpers

    static func formatTime(_ timeString: String) -> String {
        guard let date = time24.date(from: timeString) else { return timeString }
        return timeOnly.string(from: date)
    }

    static func relativeString(from date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }
}
