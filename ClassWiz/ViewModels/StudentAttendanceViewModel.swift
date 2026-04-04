// StudentAttendanceViewModel.swift
// ClassWiz – ViewModels

import SwiftUI
import Combine

@MainActor
final class StudentAttendanceViewModel: ObservableObject {
    @Published var courseStats: [CourseAttendanceStat] = []
    @Published var overallPercentage: Double = 0
    @Published var overallRisk: RiskLevel = .safe
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadAttendance(studentId: String, batchId: String?) async {
        guard !studentId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch attendance records and courses concurrently
            async let recordsTask = AttendanceService.shared.fetchAttendance(studentId: studentId)
            async let coursesTask = CourseService.shared.fetchActive()

            let records = try await recordsTask
            let courses = try await coursesTask

            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })

            // Group by courseId
            let grouped = Dictionary(grouping: records, by: \.courseId)

            var stats: [CourseAttendanceStat] = []
            for (courseId, courseRecords) in grouped {
                guard let course = courseMap[courseId] else { continue }

                let total = courseRecords.count
                let present = courseRecords.filter { $0.status == .present }.count
                let absent = total - present
                let percentage = total > 0 ? (Double(present) / Double(total)) * 100 : 0
                let risk = RiskLevel.from(percentage: percentage)

                stats.append(CourseAttendanceStat(
                    id: courseId,
                    course: course,
                    totalClasses: total,
                    presentCount: present,
                    absentCount: absent,
                    percentage: percentage,
                    risk: risk
                ))
            }

            courseStats = stats.sorted { $0.percentage < $1.percentage } // Worst first

            // Overall
            let totalAll = stats.reduce(0) { $0 + $1.totalClasses }
            let presentAll = stats.reduce(0) { $0 + $1.presentCount }
            overallPercentage = totalAll > 0 ? (Double(presentAll) / Double(totalAll)) * 100 : 0
            overallRisk = RiskLevel.from(percentage: overallPercentage)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Attendance Detail Records

    func fetchDetailRecords(studentId: String, courseId: String) async -> [AttendanceRecord] {
        do {
            return try await AttendanceService.shared.fetchAttendance(studentId: studentId, courseId: courseId)
        } catch {
            return []
        }
    }
}
