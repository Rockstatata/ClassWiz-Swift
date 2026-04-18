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
            var updatedCourse = course
            updatedCourse.isActive.toggle()
            try await CourseService.shared.update(updatedCourse)
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
        ClassWizScreen(title: "Courses", subtitle: "Manage your courses", scrollable: false) {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.courses.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Courses",
                        subtitle: "Add your first course to get started.",
                        actionTitle: "Add Course"
                    ) {
                        showAddForm = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        CWSearchBar(text: $viewModel.searchText, placeholder: "Search courses...")
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddForm = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(AppTheme.primaryGradient)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func courseRow(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Label(course.code, systemImage: "tag.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.15))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(8)
                        
                        Label("\(String(format: "%g", course.credit)) Credits", systemImage: "clock.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.15))
                            .foregroundColor(AppTheme.accent)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(course.isActive ? AppTheme.safe.opacity(0.15) : AppTheme.textSecondary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: course.isActive ? "checkmark.circle.fill" : "archivebox.fill")
                        .font(.title3)
                        .foregroundColor(course.isActive ? AppTheme.safe : AppTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
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
    @State private var credit: Double = 3.0
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
            AppTheme.background.ignoresSafeArea(edges: .all)

            Form {
                Section("Course Details") {
                    TextField("Course Code (e.g., CSE-321)", text: $code)
                        .autocapitalization(.allCharacters)

                    TextField("Course Name", text: $name)

                    Stepper("Credits: \(String(format: "%g", credit))", value: $credit, in: 0.25...6.0, step: 0.25)

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
        .navigationBarTitleDisplayMode(.inline)
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
