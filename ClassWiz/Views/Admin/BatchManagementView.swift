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
        ClassWizScreen(title: "Batches", subtitle: "Manage academic batches", scrollable: false) {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(AppTheme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.batches.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Batches",
                        subtitle: "Create your first academic batch.",
                        actionTitle: "Add Batch"
                    ) {
                        showAddForm = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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

    private func batchRow(_ batch: Batch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(batch.name)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Label(batch.semesterId, systemImage: "calendar")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Label("\(String(batch.year))", systemImage: "clock")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: AppTheme.secondary.opacity(0.3), radius: 8, y: 4)
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
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
            AppTheme.background.ignoresSafeArea(edges: .all)

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
        .navigationBarTitleDisplayMode(.inline)
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
