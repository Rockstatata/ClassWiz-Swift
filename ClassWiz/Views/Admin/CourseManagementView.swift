// CourseManagementView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

@MainActor
final class CourseManagementViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?

    var filteredCourses: [Course] {
        if searchText.isEmpty { return courses }
        return courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadCourses() async {
        isLoading = true
        do {
            courses = try await CourseService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteCourse(_ course: Course) async {
        guard let id = course.id else { return }
        do {
            try await CourseService.shared.delete(id: id)
            courses.removeAll { $0.id == id }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }

    func toggleActive(_ course: Course) async {
        guard let id = course.id else { return }
        do {
            try await CourseService.shared.toggleActive(id: id, isActive: !course.isActive)
            if let idx = courses.firstIndex(where: { $0.id == id }) {
                courses[idx].isActive.toggle()
            }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct CourseManagementView: View {
    @StateObject private var viewModel = CourseManagementViewModel()
    @State private var showAddForm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                } else if viewModel.courses.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Courses",
                        subtitle: "Add your first course to get started.",
                        actionTitle: "Add Course"
                    ) {
                        showAddForm = true
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredCourses) { course in
                            NavigationLink(destination: CourseFormView(mode: .edit(course))) {
                                courseRow(course)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteCourse(course) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    Task { await viewModel.toggleActive(course) }
                                } label: {
                                    Label(
                                        course.isActive ? "Archive" : "Activate",
                                        systemImage: course.isActive ? "archivebox" : "checkmark.circle"
                                    )
                                }
                                .tint(course.isActive ? AppTheme.warning : AppTheme.safe)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $viewModel.searchText, prompt: "Search courses...")
                }
            }
            .navigationTitle("Courses")
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
                    CourseFormView(mode: .add) {
                        showAddForm = false
                        Task { await viewModel.loadCourses() }
                    }
                }
            }
            .refreshable {
                await viewModel.loadCourses()
            }
            .task {
                await viewModel.loadCourses()
            }
        }
    }

    private func courseRow(_ course: Course) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(course.isActive ? AppTheme.primary.opacity(0.1) : AppTheme.textSecondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "book.fill")
                    .foregroundColor(course.isActive ? AppTheme.primary : AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: AppTheme.spacingSM) {
                    Text(course.code)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("•")
                        .foregroundColor(AppTheme.textSecondary)

                    Text("\(course.credit) credits")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            Text(course.isActive ? "Active" : "Archived")
                .font(.caption2.weight(.semibold))
                .foregroundColor(course.isActive ? AppTheme.safe : AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((course.isActive ? AppTheme.safe : AppTheme.textSecondary).opacity(0.12))
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Course Form View

enum FormMode<T> {
    case add
    case edit(T)
}

struct CourseFormView: View {
    let mode: FormMode<Course>
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var name = ""
    @State private var credit = 3
    @State private var isActive = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Course" : "Add Course"
    }

    init(mode: FormMode<Course>, onSave: (() -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let course) = mode {
            _code = State(initialValue: course.code)
            _name = State(initialValue: course.name)
            _credit = State(initialValue: course.credit)
            _isActive = State(initialValue: course.isActive)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section("Course Details") {
                    TextField("Course Code (e.g., CSE-321)", text: $code)
                        .autocapitalization(.allCharacters)

                    TextField("Course Name", text: $name)

                    Stepper("Credits: \(credit)", value: $credit, in: 1...6)

                    Toggle("Active", isOn: $isActive)
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
                            if isSaving {
                                ProgressView().tint(.white)
                            }
                            Text(isEditing ? "Update Course" : "Create Course")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(isSaving || code.isEmpty || name.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(title)
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

        do {
            if case .edit(var course) = mode {
                course.code = code.trimmingCharacters(in: .whitespaces)
                course.name = name.trimmingCharacters(in: .whitespaces)
                course.credit = credit
                course.isActive = isActive
                try await CourseService.shared.update(course)
            } else {
                let course = Course(
                    code: code.trimmingCharacters(in: .whitespaces),
                    name: name.trimmingCharacters(in: .whitespaces),
                    credit: credit,
                    isActive: isActive
                )
                _ = try await CourseService.shared.create(course)
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
