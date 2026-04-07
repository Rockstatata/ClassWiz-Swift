// StudentRoutineView.swift
// ClassWiz – Views/Student

import SwiftUI

struct StudentRoutineView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = StudentRoutineViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Day selector
                    daySelector
                        .padding(.top, AppTheme.spacingSM)

                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(AppTheme.primary)
                        Spacer()
                    } else if viewModel.currentDayRoutines.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "moon.zzz.fill",
                            title: "No Classes",
                            subtitle: "You have no classes scheduled for \(viewModel.selectedDay.rawValue)."
                        )
                        Spacer()
                    } else {
                        routineList
                    }
                }
            }
            .navigationTitle("My Routine")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SyncStatusBar()
                }
            }
            .refreshable {
                await viewModel.loadRoutines(batchId: appState.currentUser?.batchId)
            }
            .task {
                await viewModel.loadRoutines(batchId: appState.currentUser?.batchId)
            }
        }
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(viewModel.availableDays) { day in
                    dayPill(day)
                }
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
    }

    private func dayPill(_ day: Weekday) -> some View {
        let isSelected = viewModel.selectedDay == day
        let isToday = day == Weekday.today
        let hasClasses = !(viewModel.routinesByDay[day]?.isEmpty ?? true)

        return Button {
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

    // MARK: - Routine List

    private var routineList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMD) {
                ForEach(viewModel.currentDayRoutines) { item in
                    RoutineCard(item: item)
                }
            }
            .padding(AppTheme.spacingMD)
        }
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let item: RoutineDisplayItem

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(item.isActive ? AppTheme.safe : AppTheme.primary)
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                // Time slot
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(item.isActive ? AppTheme.safe : AppTheme.textSecondary)

                    Text(item.routine.timeSlot)
                        .font(.caption.weight(.medium))
                        .foregroundColor(item.isActive ? AppTheme.safe : AppTheme.textSecondary)

                    Spacer()

                    if item.isActive {
                        Text("NOW")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.safe))
                    }
                }

                // Course name
                Text(item.courseName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(item.courseCode)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                // Bottom row: room + teacher
                HStack(spacing: AppTheme.spacingMD) {
                    Label(item.routine.room.isEmpty ? "TBA" : item.routine.room, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Label(item.teacherName, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.leading, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
        }
        .cwCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                .stroke(item.isActive ? AppTheme.safe.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview("Routine – Student") {
    StudentRoutineView()
        .environmentObject(MockData.makeStudentAppState())
}

#Preview("Routine Card") {
    RoutineCard(item: MockData.routineDisplayItems[0])
        .padding()
        .environmentObject(MockData.makeStudentAppState())
}
