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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedules")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Add")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 70, height: 70)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.purple.opacity(0.7))
            }

            VStack(spacing: 6) {
                Text("No Schedules Yet")
                    .font(.system(size: 15, weight: .semibold))

                Text("Automatically block distracting sites\nduring work hours")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button(action: { showingAddSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Create Schedule")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.purple)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var scheduleList: some View {
        ScrollView {
            VStack(spacing: 10) {
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
    @State private var isHovered = false

    private var isActive: Bool {
        ScheduleManager.shared.isScheduleActive(schedule)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 6) {
                // URL and status
                HStack(spacing: 8) {
                    Text(schedule.url)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    if isActive {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    }
                }

                // Time range
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.purple.opacity(0.7))

                    Text("\(formatTime(hour: Int(schedule.startHour), minute: Int(schedule.startMinute))) → \(formatTime(hour: Int(schedule.endHour), minute: Int(schedule.endMinute)))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                // Days
                HStack(spacing: 3) {
                    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                    ForEach(0..<7, id: \.self) { index in
                        let dayActive = isDayActive(schedule: schedule, index: index)

                        Text(dayLabels[index])
                            .font(.system(size: 9, weight: dayActive ? .bold : .medium))
                            .foregroundColor(dayActive ? .white : .gray)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(dayActive ? Color.purple : Color.gray.opacity(0.15))
                            )
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isHovered ? .red : .gray.opacity(0.5))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(schedule.isEnabled ? Color.purple.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(schedule.isEnabled ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .opacity(schedule.isEnabled ? 1 : 0.7)
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
