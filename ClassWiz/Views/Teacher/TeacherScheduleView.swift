// TeacherScheduleView.swift
// ClassWiz – Views/Teacher

import SwiftUI
import Combine

@MainActor
final class TeacherScheduleViewModel: ObservableObject {
    @Published var routinesByDay: [Weekday: [RoutineDisplayItem]] = [:]
    @Published var selectedDay: Weekday = Weekday.today
    @Published var isLoading = false

    var currentDayRoutines: [RoutineDisplayItem] {
        (routinesByDay[selectedDay] ?? []).sorted { $0.routine.startTime < $1.routine.startTime }
    }

    func loadRoutines(teacherId: String) async {
        isLoading = true

        do {
            async let routinesTask = RoutineService.shared.fetchRoutines(forTeacher: teacherId)
            async let coursesTask = CourseService.shared.fetchAll()
            async let batchesTask = BatchService.shared.fetchAll()

            let routines = try await routinesTask
            let courses = try await coursesTask
            let batches = try await batchesTask

            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            let batchMap = Dictionary(uniqueKeysWithValues: batches.compactMap { b -> (String, Batch)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })

            var grouped: [Weekday: [RoutineDisplayItem]] = [:]
            for routine in routines {
                let item = RoutineDisplayItem(
                    id: routine.id ?? UUID().uuidString,
                    routine: routine,
                    courseName: courseMap[routine.courseId]?.name ?? "Unknown",
                    courseCode: courseMap[routine.courseId]?.code ?? "",
                    teacherName: batchMap[routine.batchId]?.name ?? "",
                    isActive: routine.isCurrentlyActive
                )
                grouped[routine.day, default: []].append(item)
            }
            routinesByDay = grouped
        } catch {
            // Silent fail - offline cache may be empty
        }

        isLoading = false
    }
}

struct TeacherScheduleView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TeacherScheduleViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    daySelector

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(AppTheme.primary)
                        Spacer()
                    } else if viewModel.currentDayRoutines.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No Classes",
                            subtitle: "No classes scheduled for \(viewModel.selectedDay.rawValue)."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacingMD) {
                                ForEach(viewModel.currentDayRoutines) { item in
                                    NavigationLink(destination: AttendanceMarkingView(routine: item)) {
                                        TeacherRoutineRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(AppTheme.spacingMD)
                        }
                    }
                }
            }
            .navigationTitle("My Schedule")
            .refreshable {
                guard let user = appState.currentUser else { return }
                await viewModel.loadRoutines(teacherId: user.id)
            }
            .task {
                guard let user = appState.currentUser else { return }
                await viewModel.loadRoutines(teacherId: user.id)
            }
        }
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(Weekday.workdays) { day in
                    let isSelected = viewModel.selectedDay == day
                    let isToday = day == Weekday.today
                    let hasClasses = !(viewModel.routinesByDay[day]?.isEmpty ?? true)

                    Button {
                        withAnimation(AppTheme.quickAnimation) {
                            viewModel.selectedDay = day
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.shortName)
                                .font(.caption.weight(.semibold))

                            if isToday {
                                Circle()
                                    .fill(isSelected ? .white : AppTheme.primary)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .frame(width: 52, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                                .fill(isSelected ? AppTheme.primary : (hasClasses ? AppTheme.surfaceSecondary : Color.clear))
                        )
                        .foregroundColor(isSelected ? .white : (hasClasses ? AppTheme.textPrimary : AppTheme.textSecondary))
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
    }
}
