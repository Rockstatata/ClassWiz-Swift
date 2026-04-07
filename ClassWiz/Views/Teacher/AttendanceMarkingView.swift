// AttendanceMarkingView.swift
// ClassWiz – Views/Teacher

import SwiftUI
import Combine

struct StudentAttendanceItem: Identifiable, Equatable {
    let id: String // studentId
    let name: String
    let email: String
    var status: AttendanceStatus
    var existingRecordId: String?
}

@MainActor
final class AttendanceMarkingViewModel: ObservableObject {
    @Published var students: [StudentAttendanceItem] = []
    @Published var selectedDate: Date = Date()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasExistingRecords = false

    let courseId: String
    let batchId: String
    let teacherId: String

    var presentCount: Int { students.filter { $0.status == .present }.count }
    var absentCount: Int { students.filter { $0.status == .absent }.count }
    var isWithinEditWindow: Bool {
        AttendanceService.isWithinEditWindow(recordDate: selectedDate)
    }

    init(courseId: String, batchId: String, teacherId: String) {
        self.courseId = courseId
        self.batchId = batchId
        self.teacherId = teacherId
    }

    func loadStudents() async {
        isLoading = true
        errorMessage = nil

        do {
            let batchStudents = try await UserService.shared.fetchStudents(inBatch: batchId)
            let existingRecords = try await AttendanceService.shared.fetchAttendance(
                courseId: courseId,
                batchId: batchId,
                date: selectedDate
            )

            let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { r -> (String, AttendanceRecord) in
                (r.studentId, r)
            })

            hasExistingRecords = !existingRecords.isEmpty

            students = batchStudents.map { student in
                let existing = existingMap[student.id]
                return StudentAttendanceItem(
                    id: student.id,
                    name: student.name,
                    email: student.email,
                    status: existing?.status ?? .present,
                    existingRecordId: existing?.id
                )
            }.sorted { $0.name < $1.name }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleStatus(for studentId: String) {
        guard let index = students.firstIndex(where: { $0.id == studentId }) else { return }
        students[index].status = students[index].status == .present ? .absent : .present
        HapticManager.selection()
    }

    func markAllPresent() {
        for i in students.indices {
            students[i].status = .present
        }
        HapticManager.lightImpact()
    }

    func markAllAbsent() {
        for i in students.indices {
            students[i].status = .absent
        }
        HapticManager.lightImpact()
    }

    func submitAttendance() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            let records = students.map { student in
                AttendanceRecord(
                    studentId: student.id,
                    courseId: courseId,
                    date: Calendar.current.startOfDay(for: selectedDate),
                    status: student.status,
                    markedBy: teacherId
                )
            }

            // If existing records, delete them first then re-create
            if hasExistingRecords {
                for student in students {
                    if let existingId = student.existingRecordId {
                        try await AttendanceService.shared.deleteAttendance(id: existingId)
                    }
                }
            }

            try await AttendanceService.shared.markAttendance(records: records)
            successMessage = "Attendance saved successfully!"
            hasExistingRecords = true
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }

        isSaving = false
    }
}

struct AttendanceMarkingView: View {
    @EnvironmentObject private var appState: AppState
    let routine: RoutineDisplayItem
    @StateObject private var viewModel: AttendanceMarkingViewModel
    @State private var showConfirmation = false

    init(routine: RoutineDisplayItem) {
        self.routine = routine
        _viewModel = StateObject(wrappedValue: AttendanceMarkingViewModel(
            courseId: routine.routine.courseId,
            batchId: routine.routine.batchId,
            teacherId: routine.routine.teacherId
        ))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(AppTheme.primary)
            } else {
                VStack(spacing: 0) {
                    headerCard
                    bulkActions
                    studentList
                    submitBar
                }
            }
        }
        .navigationTitle("Mark Attendance")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Submission", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Submit") {
                Task { await viewModel.submitAttendance() }
            }
        } message: {
            Text("Mark \(viewModel.presentCount) present and \(viewModel.absentCount) absent for \(routine.courseName)?")
        }
        .task {
            await viewModel.loadStudents()
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task { await viewModel.loadStudents() }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: AppTheme.spacingSM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.courseName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(routine.courseCode) • \(routine.routine.room.isEmpty ? "No Room" : routine.routine.room)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(AppTheme.primary)
            }

            if viewModel.hasExistingRecords {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                    Text("Editing existing attendance for this date")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.warning)
            }

            // Success / Error messages
            if let success = viewModel.successMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(success)
                }
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.safe)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text(error)
                }
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.critical)
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.surface)
    }

    // MARK: - Bulk Actions

    private var bulkActions: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Button {
                viewModel.markAllPresent()
            } label: {
                Label("All Present", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.safe)
            }

            Spacer()

            // Counter
            HStack(spacing: AppTheme.spacingMD) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.safe)
                    Text("\(viewModel.presentCount)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }

                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.critical)
                    Text("\(viewModel.absentCount)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
            }

            Spacer()

            Button {
                viewModel.markAllAbsent()
            } label: {
                Label("All Absent", systemImage: "xmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.critical)
            }
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
        .background(AppTheme.surfaceSecondary)
    }

    // MARK: - Student List

    private var studentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.students) { student in
                    studentRow(student)

                    if student.id != viewModel.students.last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
        }
    }

    private func studentRow(_ student: StudentAttendanceItem) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            // Avatar
            ZStack {
                Circle()
                    .fill(student.status == .present ?
                          AppTheme.safe.opacity(0.15) :
                          AppTheme.critical.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(String(student.name.prefix(1)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(student.status == .present ? AppTheme.safe : AppTheme.critical)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)

                Text(student.email)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                viewModel.toggleStatus(for: student.id)
            } label: {
                Image(systemName: student.status.icon)
                    .font(.title2)
                    .foregroundColor(student.status.color)
                    .symbolEffect(.bounce, value: student.status)
            }
        }
        .padding(.vertical, AppTheme.spacingSM)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleStatus(for: student.id)
        }
    }

    // MARK: - Submit Bar

    private var submitBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showConfirmation = true
            } label: {
                Text(viewModel.hasExistingRecords ? "Update Attendance" : "Submit Attendance")
            }
            .buttonStyle(CWPrimaryButtonStyle(isLoading: viewModel.isSaving))
            .disabled(viewModel.isSaving || viewModel.students.isEmpty)
            .padding(AppTheme.spacingMD)
            .padding(.bottom, AppTheme.spacingSM)
        }
        .background(AppTheme.surface.ignoresSafeArea(edges: .bottom))
    }
}
