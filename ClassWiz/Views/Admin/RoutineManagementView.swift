// RoutineManagementView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

struct RoutineDisplayAdmin: Identifiable, Equatable {
    let id: String
    let routine: Routine
    var courseName: String
    var courseCode: String
    var teacherName: String
    var batchName: String
}

@MainActor
final class RoutineManagementViewModel: ObservableObject {
    @Published var routines: [RoutineDisplayAdmin] = []
    @Published var isLoading = false
    @Published var selectedDay: Weekday = Weekday.today
    @Published var errorMessage: String?

    var filteredRoutines: [RoutineDisplayAdmin] {
        routines.filter { $0.routine.day == selectedDay }
            .sorted { $0.routine.startTime < $1.routine.startTime }
    }

    // Lookup data for form pickers
    @Published var courses: [Course] = []
    @Published var batches: [Batch] = []
    @Published var teachers: [AppUser] = []

    func loadRoutines() async {
        isLoading = true

        do {
            async let routinesTask = RoutineService.shared.fetchAll()
            async let coursesTask = CourseService.shared.fetchAll()
            async let batchesTask = BatchService.shared.fetchAll()
            async let teachersTask = UserService.shared.fetchUsers(byRole: .teacher)

            let allRoutines = try await routinesTask
            courses = try await coursesTask
            batches = try await batchesTask
            teachers = try await teachersTask

            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            let batchMap = Dictionary(uniqueKeysWithValues: batches.compactMap { b -> (String, Batch)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })
            let teacherMap = Dictionary(uniqueKeysWithValues: teachers.map { ($0.id, $0) })

            routines = allRoutines.compactMap { r -> (RoutineDisplayAdmin)? in
                guard let id = r.id else { return nil }
                return RoutineDisplayAdmin(
                    id: id,
                    routine: r,
                    courseName: courseMap[r.courseId]?.name ?? "Unknown",
                    courseCode: courseMap[r.courseId]?.code ?? "",
                    teacherName: teacherMap[r.teacherId]?.name ?? "Unknown",
                    batchName: batchMap[r.batchId]?.name ?? "Unknown"
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteRoutine(id: String) async {
        do {
            try await RoutineService.shared.delete(id: id)
            routines.removeAll { $0.id == id }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}

struct RoutineManagementView: View {
    @StateObject private var viewModel = RoutineManagementViewModel()
    @State private var showAddForm = false

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
                    } else if viewModel.filteredRoutines.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No Routines",
                            subtitle: "No routines scheduled for \(viewModel.selectedDay.rawValue)."
                        )
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.filteredRoutines) { item in
                                NavigationLink(destination: RoutineFormView(
                                    mode: .edit(item.routine),
                                    courses: viewModel.courses,
                                    batches: viewModel.batches,
                                    teachers: viewModel.teachers
                                )) {
                                    routineRow(item)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteRoutine(id: item.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                NavigationStack {
                    RoutineFormView(
                        mode: .add,
                        courses: viewModel.courses,
                        batches: viewModel.batches,
                        teachers: viewModel.teachers
                    ) {
                        showAddForm = false
                        Task { await viewModel.loadRoutines() }
                    }
                }
            }
            .refreshable {
                await viewModel.loadRoutines()
            }
            .task {
                await viewModel.loadRoutines()
            }
        }
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(Weekday.allCases) { day in
                    let isSelected = viewModel.selectedDay == day
                    let count = viewModel.routines.filter { $0.routine.day == day }.count

                    Button {
                        withAnimation(AppTheme.quickAnimation) {
                            viewModel.selectedDay = day
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.shortName)
                                .font(.caption.weight(.semibold))

                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textSecondary)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                                .fill(isSelected ? AppTheme.primary : (count > 0 ? AppTheme.surfaceSecondary : Color.clear))
                        )
                        .foregroundColor(isSelected ? .white : (count > 0 ? AppTheme.textPrimary : AppTheme.textSecondary))
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
    }

    private func routineRow(_ item: RoutineDisplayAdmin) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text(item.routine.timeSlot)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.primary)

                Spacer()

                if !item.routine.room.isEmpty {
                    Label(item.routine.room, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Text(item.courseName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: AppTheme.spacingMD) {
                Label(item.teacherName, systemImage: "person.fill")
                Label(item.batchName, systemImage: "person.3")
            }
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Routine Form View

struct RoutineFormView: View {
    let mode: FormMode<Routine>
    let courses: [Course]
    let batches: [Batch]
    let teachers: [AppUser]
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourseId = ""
    @State private var selectedTeacherId = ""
    @State private var selectedBatchId = ""
    @State private var selectedDay: Weekday = .sunday
    @State private var startTime = "09:00"
    @State private var endTime = "10:30"
    @State private var room = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var hasConflict = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: FormMode<Routine>, courses: [Course], batches: [Batch], teachers: [AppUser], onSave: (() -> Void)? = nil) {
        self.mode = mode
        self.courses = courses
        self.batches = batches
        self.teachers = teachers
        self.onSave = onSave

        if case .edit(let routine) = mode {
            _selectedCourseId = State(initialValue: routine.courseId)
            _selectedTeacherId = State(initialValue: routine.teacherId)
            _selectedBatchId = State(initialValue: routine.batchId)
            _selectedDay = State(initialValue: routine.day)
            _startTime = State(initialValue: routine.startTime)
            _endTime = State(initialValue: routine.endTime)
            _room = State(initialValue: routine.room)
        }
    }

    private let timeSlots = stride(from: 8, through: 18, by: 1).flatMap { hour in
        ["00", "30"].map { min in String(format: "%02d:%@", hour, min) }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section("Class Details") {
                    Picker("Course", selection: $selectedCourseId) {
                        Text("Select Course").tag("")
                        ForEach(courses) { course in
                            Text(course.displayName).tag(course.id ?? "")
                        }
                    }

                    Picker("Teacher", selection: $selectedTeacherId) {
                        Text("Select Teacher").tag("")
                        ForEach(teachers) { teacher in
                            Text(teacher.name).tag(teacher.id)
                        }
                    }

                    Picker("Batch", selection: $selectedBatchId) {
                        Text("Select Batch").tag("")
                        ForEach(batches) { batch in
                            Text(batch.name).tag(batch.id ?? "")
                        }
                    }
                }

                Section("Schedule") {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }

                    Picker("Start Time", selection: $startTime) {
                        ForEach(timeSlots, id: \.self) { time in
                            Text(DateFormatters.formatTime(time)).tag(time)
                        }
                    }

                    Picker("End Time", selection: $endTime) {
                        ForEach(timeSlots, id: \.self) { time in
                            Text(DateFormatters.formatTime(time)).tag(time)
                        }
                    }

                    TextField("Room (e.g., Lab-301)", text: $room)
                }

                if hasConflict {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.warning)
                            Text("Room conflict detected! Another class is scheduled in this room at this time.")
                                .font(.caption)
                                .foregroundColor(AppTheme.warning)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(AppTheme.critical)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView().tint(.white) }
                            Text(isEditing ? "Update Routine" : "Create Routine")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(isSaving || selectedCourseId.isEmpty || selectedTeacherId.isEmpty || selectedBatchId.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(isEditing ? "Edit Routine" : "Add Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !isEditing {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        hasConflict = false

        // Check conflict
        if !room.isEmpty {
            do {
                var excludeId: String?
                if case .edit(let routine) = mode { excludeId = routine.id }
                let conflict = try await RoutineService.shared.checkConflict(
                    day: selectedDay, startTime: startTime, endTime: endTime,
                    room: room, excludeId: excludeId
                )
                if conflict {
                    hasConflict = true
                    isSaving = false
                    HapticManager.warning()
                    return
                }
            } catch { /* proceed */ }
        }

        do {
            if case .edit(var routine) = mode {
                routine.courseId = selectedCourseId
                routine.teacherId = selectedTeacherId
                routine.batchId = selectedBatchId
                routine.day = selectedDay
                routine.startTime = startTime
                routine.endTime = endTime
                routine.room = room
                try await RoutineService.shared.update(routine)
            } else {
                let routine = Routine(
                    courseId: selectedCourseId,
                    teacherId: selectedTeacherId,
                    batchId: selectedBatchId,
                    day: selectedDay,
                    startTime: startTime,
                    endTime: endTime,
                    room: room
                )
                _ = try await RoutineService.shared.create(routine)
            }

            HapticManager.success()
            onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }

        isSaving = false
    }
}
