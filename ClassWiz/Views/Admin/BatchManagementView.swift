// BatchManagementView.swift
// ClassWiz – Views/Admin

import SwiftUI
import Combine

@MainActor
final class BatchManagementViewModel: ObservableObject {
    @Published var batches: [Batch] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadBatches() async {
        isLoading = true
        do {
            batches = try await BatchService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteBatch(_ batch: Batch) async {
        guard let id = batch.id else { return }
        do {
            try await BatchService.shared.delete(id: id)
            batches.removeAll { $0.id == id }
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}

struct BatchManagementView: View {
    @StateObject private var viewModel = BatchManagementViewModel()
    @State private var showAddForm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                } else if viewModel.batches.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Batches",
                        subtitle: "Create your first academic batch.",
                        actionTitle: "Add Batch"
                    ) {
                        showAddForm = true
                    }
                } else {
                    List {
                        ForEach(viewModel.batches) { batch in
                            NavigationLink(destination: BatchFormView(mode: .edit(batch))) {
                                batchRow(batch)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteBatch(batch) }
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
            .navigationTitle("Batches")
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
                    BatchFormView(mode: .add) {
                        showAddForm = false
                        Task { await viewModel.loadBatches() }
                    }
                }
            }
            .refreshable {
                await viewModel.loadBatches()
            }
            .task {
                await viewModel.loadBatches()
            }
        }
    }

    private func batchRow(_ batch: Batch) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "person.3.fill")
                    .foregroundColor(AppTheme.secondary)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(batch.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: AppTheme.spacingSM) {
                    Text("Semester: \(batch.semesterId)")
                    Text("•")
                    Text("Year: \(batch.year)")
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Batch Form View

struct BatchFormView: View {
    let mode: FormMode<Batch>
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var semesterId = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: FormMode<Batch>, onSave: (() -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let batch) = mode {
            _name = State(initialValue: batch.name)
            _semesterId = State(initialValue: batch.semesterId)
            _year = State(initialValue: batch.year)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Form {
                Section("Batch Details") {
                    TextField("Batch Name (e.g., CSE 3A)", text: $name)
                    TextField("Semester ID (e.g., Spring 2026)", text: $semesterId)
                    Stepper("Year: \(year)", value: $year, in: 2020...2030)
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
                            Text(isEditing ? "Update Batch" : "Create Batch")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(isSaving || name.isEmpty || semesterId.isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(isEditing ? "Edit Batch" : "Add Batch")
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
            if case .edit(var batch) = mode {
                batch.name = name.trimmingCharacters(in: .whitespaces)
                batch.semesterId = semesterId.trimmingCharacters(in: .whitespaces)
                batch.year = year
                try await BatchService.shared.update(batch)
            } else {
                let batch = Batch(
                    name: name.trimmingCharacters(in: .whitespaces),
                    semesterId: semesterId.trimmingCharacters(in: .whitespaces),
                    year: year
                )
                _ = try await BatchService.shared.create(batch)
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
