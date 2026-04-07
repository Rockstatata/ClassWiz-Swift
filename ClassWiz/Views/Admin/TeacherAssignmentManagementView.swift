// TeacherAssignmentManagementView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

struct AssignmentDisplayItem: Identifiable, Equatable {
    let id: String
    let assignment: TeacherAssignment
    var teacherName: String
    var courseName: String
    var courseCode: String
    var batchName: String
}

@MainActor
final class TeacherAssignmentManagementViewModel: ObservableObject {
    @Published var assignments: [AssignmentDisplayItem] = []
    @Published var teachers: [AppUser] = []
    @Published var courses: [Course] = []
    @Published var batches: [Batch] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadData() async {
        isLoading = true

        do {
            async let assignmentsTask = TeacherAssignmentService.shared.fetchAll()
            async let teachersTask = UserService.shared.fetchUsers(byRole: .teacher)
            async let coursesTask = CourseService.shared.fetchAll()
            async let batchesTask = BatchService.shared.fetchAll()

            let rawAssignments = try await assignmentsTask
            teachers = try await teachersTask
            courses = try await coursesTask
            batches = try await batchesTask

            let teacherMap = Dictionary(uniqueKeysWithValues: teachers.map { ($0.id, $0) })
            let courseMap = Dictionary(uniqueKeysWithValues: courses.compactMap { c -> (String, Course)? in
                guard let id = c.id else { return nil }
                return (id, c)
            })
            let batchMap = Dictionary(uniqueKeysWithValues: batches.compactMap { b -> (String, Batch)? in
                guard let id = b.id else { return nil }
                return (id, b)
            })

            assignments = rawAssignments.compactMap { a -> (AssignmentDisplayItem)? in
                guard let id = a.id else { return nil }
                return AssignmentDisplayItem(
                    id: id,
                    assignment: a,
                    teacherName: teacherMap[a.teacherId]?.name ?? "Unknown",
                    courseName: courseMap[a.courseId]?.name ?? "Unknown",
                    courseCode: courseMap[a.courseId]?.code ?? "",
                    batchName: batchMap[a.batchId]?.name ?? "Unknown"
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteAssignment(id: String) async {
        do {
            try await TeacherAssignmentService.shared.delete(id: id)
            assignments.removeAll { $0.id == id }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}

struct TeacherAssignmentManagementView: View {
    @StateObject private var viewModel = TeacherAssignmentManagementViewModel()
    @State private var showAddForm = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(AppTheme.primary)
            } else if viewModel.assignments.isEmpty {
                EmptyStateView(
                    icon: "person.badge.plus",
                    title: "No Assignments",
                    subtitle: "Assign teachers to courses and batches.",
                    actionTitle: "Add Assignment"
                ) {
                    showAddForm = true
                }
            } else {
                List {
                    ForEach(viewModel.assignments) { item in
                        assignmentRow(item)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteAssignment(id: item.id) }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Teacher Assignments")
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
                TeacherAssignmentFormView(
                    teachers: viewModel.teachers,
                    courses: viewModel.courses,
                    batches: viewModel.batches
                ) {
                    showAddForm = false
                    Task { await viewModel.loadData() }
                }
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }

    private func assignmentRow(_ item: AssignmentDisplayItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Image(systemName: "person.crop.rectangle.fill")
                    .foregroundColor(AppTheme.primary)

                Text(item.teacherName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            HStack(spacing: AppTheme.spacingMD) {
                Label(item.courseName, systemImage: "book")
                Label(item.batchName, systemImage: "person.3")
            }
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Teacher Assignment Form

struct TeacherAssignmentFormView: View {
    let teachers: [AppUser]
    let courses: [Course]
    let batches: [Batch]
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeacherId = ""
    @State private var selectedCourseId = ""
    @State private var selectedBatchId = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section("Assignment Details") {
                    Picker("Teacher", selection: $selectedTeacherId) {
                        Text("Select Teacher").tag("")
                        ForEach(teachers) { teacher in
                            Text(teacher.name).tag(teacher.id)
                        }
                    }

                    Picker("Course", selection: $selectedCourseId) {
                        Text("Select Course").tag("")
                        ForEach(courses) { course in
                            Text(course.displayName).tag(course.id ?? "")
                        }
                    }

                    Picker("Batch", selection: $selectedBatchId) {
                        Text("Select Batch").tag("")
                        ForEach(batches) { batch in
                            Text(batch.name).tag(batch.id ?? "")
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(AppTheme.critical).font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView().tint(.white) }
                            Text("Create Assignment").font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(isSaving || selectedTeacherId.isEmpty || selectedCourseId.isEmpty || selectedBatchId.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("New Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            // Check for duplicates
            let exists = try await TeacherAssignmentService.shared.isTeacherAssigned(
                teacherId: selectedTeacherId,
                courseId: selectedCourseId,
                batchId: selectedBatchId
            )
            if exists {
                errorMessage = "This assignment already exists."
                HapticManager.warning()
                isSaving = false
                return
            }

            let assignment = TeacherAssignment(
                teacherId: selectedTeacherId,
                courseId: selectedCourseId,
                batchId: selectedBatchId
            )
            _ = try await TeacherAssignmentService.shared.create(assignment)

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
