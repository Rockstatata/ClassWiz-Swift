// StudentRoutineViewModel.swift
// ClassWiz – ViewModels

import SwiftUI
import Combine

struct RoutineDisplayItem: Identifiable, Equatable {
    let id: String
    let routine: Routine
    var courseName: String = ""
    var courseCode: String = ""
    var teacherName: String = ""
    var isActive: Bool = false
}

@MainActor
final class StudentRoutineViewModel: ObservableObject {
    @Published var routinesByDay: [Weekday: [RoutineDisplayItem]] = [:]
    @Published var selectedDay: Weekday = Weekday.today
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var courses: [String: Course] = [:]
    private var teachers: [String: AppUser] = [:]

    var currentDayRoutines: [RoutineDisplayItem] {
        (routinesByDay[selectedDay] ?? []).sorted { $0.routine.startTime < $1.routine.startTime }
    }

    var availableDays: [Weekday] {
        Weekday.workdays
    }

    func loadRoutines(batchId: String?) async {
        guard let batchId, !batchId.isEmpty else {
            errorMessage = "No batch assigned to your account."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data concurrently
            async let routinesTask = RoutineService.shared.fetchRoutines(forBatch: batchId)
            async let coursesTask = CourseService.shared.fetchAll()
            async let teachersTask = UserService.shared.fetchUsers(byRole: .teacher)

            let routines = try await routinesTask
            let allCourses = try await coursesTask
            let allTeachers = try await teachersTask

            // Build lookup maps
            courses = Dictionary(uniqueKeysWithValues: allCourses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            teachers = Dictionary(uniqueKeysWithValues: allTeachers.map { ($0.id, $0) })

            // Group by day
            var grouped: [Weekday: [RoutineDisplayItem]] = [:]
            for routine in routines {
                let item = RoutineDisplayItem(
                    id: routine.id ?? UUID().uuidString,
                    routine: routine,
                    courseName: courses[routine.courseId]?.name ?? "Unknown Course",
                    courseCode: courses[routine.courseId]?.code ?? "",
                    teacherName: teachers[routine.teacherId]?.name ?? "TBA",
                    isActive: routine.isCurrentlyActive
                )
                grouped[routine.day, default: []].append(item)
            }
            routinesByDay = grouped
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
