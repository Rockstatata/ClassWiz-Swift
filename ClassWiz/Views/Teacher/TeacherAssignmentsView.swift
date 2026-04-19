// TeacherAssignmentsView.swift
// ClassWiz – Views/Teacher

import SwiftUI

struct TeacherAssignmentsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var assignments: [Assignment] = []
    @State private var isLoading = false
    @State private var showCreateModal = false

    var body: some View {
        ClassWizScreen(title: "Assignments", subtitle: "Manage Class Tasks", showNotification: false, scrollable: true) {
            ZStack {
                if isLoading {
                    ProgressView("Loading Assignments...")
                        .tint(AppTheme.primary)
                        .padding(.top, 50)
                } else if assignments.isEmpty {
                    EmptyStateView(icon: "doc.text.fill", title: "No Assignments", subtitle: "Create assignments for your classes.")
                        .padding(.top, 50)
                } else {
                    VStack(spacing: AppTheme.spacingMD) {
                        ForEach(assignments) { assignment in
                            NavigationLink(destination: TeacherAssignmentGradingView(assignment: assignment)) {
                                teacherAssignmentCard(assignment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateModal = true
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
                    }
                }
            }
            .padding(.bottom, AppTheme.spacingMD)
        }
        .sheet(isPresented: $showCreateModal) {
            TeacherCreateAssignmentView(onSave: loadAssignments)
        }
        .task {
            loadAssignments()
        }
        .refreshable {
            loadAssignments()
        }
    }

    private func teacherAssignmentCard(_ assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                spanBadge(icon: "timer", text: "Due \(DateFormatters.mediumDate.string(from: assignment.dueDate))", color: AppTheme.critical)
                Spacer()
                Image(systemName: "paintbrush.pointed")
                    .foregroundColor(AppTheme.primary)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                Text(assignment.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            HStack {
                Text("Grade / Review Submissions")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(AppTheme.primary.opacity(0.1)))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface)
                .shadow(color: Color.black.opacity(0.04), radius: 15, y: 5)
        )
    }

    private func spanBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12))
            Text(text).font(.system(size: 10, weight: .bold)).textCase(.uppercase)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.15)))
    }

    private func loadAssignments() {
        guard let teacherId = appState.currentUser?.id else { return }
        isLoading = true
        Task {
            do {
                let fetched = try await AssignmentService.shared.fetchAssignments(forTeacher: teacherId)
                await MainActor.run {
                    self.assignments = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct TeacherCreateAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    var onSave: () -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var courseId = ""
    @State private var dueDate = Date()
    @State private var isSaving = false
    
    @State private var courses: [(id: String, name: String)] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Picker("Course", selection: $courseId) {
                        Text("Select a Course").tag("")
                        ForEach(courses, id: \.id) { course in
                            Text(course.name).tag(course.id)
                        }
                    }
                    DatePicker("Due Date", selection: $dueDate)
                }

                Section {
                    Button(action: saveAssignment) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(.white)
                            }
                            Text("Create Assignment")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .disabled(title.isEmpty || courseId.isEmpty || isSaving)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                guard let teacherId = appState.currentUser?.id else { return }
                if let assigned = try? await TeacherAssignmentService.shared.fetchAssignments(forTeacher: teacherId) {
                    for a in assigned {
                        if let c = try? await CourseService.shared.fetchCourse(id: a.courseId) {
                            courses.append((id: a.courseId, name: c.displayName))
                        }
                    }
                }
            }
        }
    }

    private func saveAssignment() {
        guard let teacherId = appState.currentUser?.id else { return }
        isSaving = true
        
        let assignment = Assignment(courseId: courseId, teacherId: teacherId, title: title, description: description, dueDate: dueDate)
        
        Task {
            do {
                try await AssignmentService.shared.createAssignment(assignment)
                await MainActor.run {
                    isSaving = false
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run { isSaving = false }
            }
        }
    }
}

struct TeacherAssignmentGradingView: View {
    let assignment: Assignment
    @EnvironmentObject private var appState: AppState
    @State private var submissions: [AssignmentSubmission] = []
    @State private var isLoading = false
    
    @State private var gradingSubmission: AssignmentSubmission?
    @State private var activeGrade = ""
    @State private var activeFeedback = ""

    var body: some View {
        ClassWizScreen(title: "Submissions", subtitle: assignment.title, showNotification: false, showProfile: false, showBackButton: true, scrollable: true) {
            VStack(spacing: AppTheme.spacingMD) {
                if isLoading {
                    ProgressView().tint(AppTheme.primary)
                } else if submissions.isEmpty {
                    EmptyStateView(icon: "doc.text.magnifyingglass", title: "No Submissions", subtitle: "Students have not submitted yet.")
                } else {
                    ForEach(submissions) { sub in
                        submissionCard(sub)
                    }
                }
            }
            .padding(.bottom, AppTheme.spacingMD)
        }
        .task { loadSubmissions() }
        .refreshable { loadSubmissions() }
        .sheet(item: $gradingSubmission) { sub in
            gradingModal(sub)
        }
    }
    
    private func submissionCard(_ sub: AssignmentSubmission) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(AppTheme.primaryGradient).frame(width: 40, height: 40)
                    .overlay(Text("S").foregroundColor(.white).font(.headline))
                VStack(alignment: .leading) {
                    Text(sub.studentId) // Real app would resolve User Name from UserService
                        .font(.body.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Submitted: \(DateFormatters.mediumDate.string(from: sub.submittedAt))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if let g = sub.grade {
                    Text(g)
                        .font(.headline)
                        .foregroundColor(AppTheme.safe)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(AppTheme.safe.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("PENDING")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.warning)
                }
            }
            
            if let link = sub.documentURL {
                Link(destination: URL(string: link) ?? URL(fileURLWithPath: "")) {
                    HStack {
                        Image(systemName: "link")
                        Text("View Document")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.primary)
                    .padding(10)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Button("Review & Grade") {
                gradingSubmission = sub
                activeGrade = sub.grade ?? ""
                activeFeedback = sub.feedback ?? ""
            }
            .font(.subheadline.weight(.bold))
            .foregroundColor(.white)
            .padding(.vertical, 10).frame(maxWidth: .infinity)
            .background(Capsule().fill(AppTheme.secondary))
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(AppTheme.surface).shadow(color: .black.opacity(0.04), radius: 10, y: 5))
    }
    
    private func loadSubmissions() {
        isLoading = true
        Task {
            do {
                if let aid = assignment.id {
                    let s = try await AssignmentService.shared.fetchSubmissions(forAssignment: aid)
                    await MainActor.run { self.submissions = s; self.isLoading = false }
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func gradingModal(_ sub: AssignmentSubmission) -> some View {
        NavigationStack {
            Form {
                Section("Assign Grade") {
                    TextField("Score / Grade (e.g. 95/100, A-)", text: $activeGrade)
                }
                Section("Feedback (Optional)") {
                    TextEditor(text: $activeFeedback)
                        .frame(height: 100)
                }
                Section {
                    Button(action: { submitGrade(sub) }) {
                        HStack {
                            Spacer()
                            Text("Save Grade").font(.headline.weight(.bold)).foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                }
            }
            .navigationTitle("Grade Submission")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { gradingSubmission = nil }
                }
            }
        }
    }
    
    private func submitGrade(_ sub: AssignmentSubmission) {
        var updated = sub
        updated.grade = activeGrade
        updated.feedback = activeFeedback
        
        Task {
            do {
                try await AssignmentService.shared.gradeSubmission(id: updated.id ?? "", grade: activeGrade, feedback: activeFeedback)
                await MainActor.run {
                    if let idx = submissions.firstIndex(where: { $0.id == sub.id }) {
                        submissions[idx] = updated
                    }
                    gradingSubmission = nil
                }
            } catch { } // Error handling mock
        }
    }
}
