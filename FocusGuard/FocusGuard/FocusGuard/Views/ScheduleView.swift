//
//  ScheduleView.swift
//  FocusGuard
//
//  UI for creating and managing scheduled blocks
//

import SwiftUI

struct ScheduleView: View {
    @State private var schedules: [BlockSchedule] = []
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Scheduled Blocks")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            if schedules.isEmpty {
                emptyState
            } else {
                scheduleList
            }
        }
        .padding()
        .onAppear {
            loadSchedules()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddScheduleSheet(onSave: { schedule in
                loadSchedules()
            })
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(.gray)

            Text("No Scheduled Blocks")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Create a schedule to automatically block sites at specific times")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Schedule") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var scheduleList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(schedules, id: \.id) { schedule in
                    ScheduleRowView(schedule: schedule, onToggle: {
                        ScheduleManager.shared.toggleSchedule(schedule)
                        loadSchedules()
                    }, onDelete: {
                        ScheduleManager.shared.deleteSchedule(schedule)
                        loadSchedules()
                    })
                }
            }
        }
    }

    private func loadSchedules() {
        schedules = DataService.shared.getAllSchedules()
    }
}

struct ScheduleRowView: View {
    let schedule: BlockSchedule
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(schedule.url)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)

                    if ScheduleManager.shared.isScheduleActive(schedule) {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(formatTime(hour: Int(schedule.startHour), minute: Int(schedule.startMinute))) - \(formatTime(hour: Int(schedule.endHour), minute: Int(schedule.endMinute)))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                    ForEach(0..<7, id: \.self) { index in
                        let isActive = isDayActive(schedule: schedule, index: index)

                        Text(dayLabels[index])
                            .font(.caption2)
                            .fontWeight(isActive ? .bold : .regular)
                            .foregroundColor(isActive ? .blue : .gray)
                            .frame(width: 18, height: 18)
                            .background(isActive ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let ampm = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }

    private func isDayActive(schedule: BlockSchedule, index: Int) -> Bool {
        switch index {
        case 0: return schedule.sunday
        case 1: return schedule.monday
        case 2: return schedule.tuesday
        case 3: return schedule.wednesday
        case 4: return schedule.thursday
        case 5: return schedule.friday
        case 6: return schedule.saturday
        default: return false
        }
    }
}

struct AddScheduleSheet: View {
    @Environment(\.dismiss) var dismiss

    let onSave: (BlockSchedule) -> Void

    @State private var url = ""
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 17
    @State private var endMinute = 0
    @State private var days = [false, true, true, true, true, true, false] // Mon-Fri by default

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Scheduled Block")
                .font(.headline)

            // URL input
            VStack(alignment: .leading, spacing: 4) {
                Text("Website")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., x.com", text: $url)
                    .textFieldStyle(.roundedBorder)
            }

            // Time pickers
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("Hour", selection: $startHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)").tag(h)
                            }
                        }
                        .frame(width: 60)

                        Text(":")

                        Picker("Minute", selection: $startMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .frame(width: 60)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("End Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("Hour", selection: $endHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)").tag(h)
                            }
                        }
                        .frame(width: 60)

                        Text(":")

                        Picker("Minute", selection: $endMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .frame(width: 60)
                    }
                }
            }

            // Day selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Days")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Toggle(dayNames[index], isOn: $days[index])
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                    }
                }
            }

            Divider()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    saveSchedule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func saveSchedule() {
        let schedule = ScheduleManager.shared.createSchedule(
            url: url,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            days: days
        )

        onSave(schedule)
        dismiss()
    }
}
