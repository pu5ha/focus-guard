//
//  MenuBarView.swift
//  FocusGuard
//
//  Main menu bar popup interface
//

import SwiftUI
import Combine
import ServiceManagement

struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with shame stats
            headerView

            // Always visible shame stats bar
            shameStatsBar

            Divider()

            // Tab picker
            HStack(spacing: 4) {
                TabButton(title: "Blocks", icon: "shield.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Schedules", icon: "calendar.badge.clock", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Settings", icon: "gearshape.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Content based on selected tab
            switch selectedTab {
            case 0:
                blocksTab
            case 1:
                schedulesTab
            case 2:
                settingsTab
            default:
                blocksTab
            }
        }
        .frame(width: 380)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            // App icon with gradient background
            ZStack {
                LinearGradient(
                    colors: [.purple, .purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 38, height: 38)
                .cornerRadius(10)
                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: "shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("FocusGuard")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text("Stay focused, stay productive")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.purple.opacity(0.7))
            }

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color(NSColor.controlBackgroundColor)
                LinearGradient(
                    colors: [.purple.opacity(0.03), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    // Always visible shame stats
    private var shameStatsBar: some View {
        HStack(spacing: 0) {
            // Bypass count
            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(viewModel.todayStats.bypassCount)",
                label: "Bypasses",
                color: viewModel.todayStats.bypassCount > 0 ? .orange : .gray,
                isWarning: viewModel.todayStats.bypassCount > 0
            )

            // Time wasted
            StatCard(
                icon: "clock.fill",
                value: "\(viewModel.todayStats.totalWastedMinutes)m",
                label: "Wasted",
                color: viewModel.todayStats.totalWastedMinutes > 0 ? .red : .gray,
                isWarning: viewModel.todayStats.totalWastedMinutes > 0
            )

            // Blocks activated
            StatCard(
                icon: "checkmark.shield.fill",
                value: "\(viewModel.todayStats.blocksActivated)",
                label: "Blocked",
                color: .green,
                isWarning: false
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Blocks Tab

    private var blocksTab: some View {
        VStack(spacing: 0) {
            // Active blocks section
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.activeBlocks.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(viewModel.activeBlocks, id: \.id) { block in
                            BlockRowView(block: block) {
                                viewModel.removeBlockWithFriction(block)
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 250)

            Divider()

            // Quick actions
            quickActionsView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "shield.slash")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.blue.opacity(0.6))
            }

            VStack(spacing: 6) {
                Text("No Active Blocks")
                    .font(.system(size: 16, weight: .semibold))

                Text("Add websites below to start\nblocking distractions")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    @State private var showCustomDuration = false
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0

    private var quickActionsView: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("Quick Block")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            // URL input
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    TextField("Enter website (e.g., x.com)", text: $viewModel.newURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

                Button(action: { viewModel.addBlock() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.newURL.isEmpty ? .gray.opacity(0.4) : .blue)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.newURL.isEmpty)
            }

            // Quick block buttons
            HStack(spacing: 8) {
                QuickBlockButton(title: "1 Hour", duration: .oneHour, url: $viewModel.newURL)
                QuickBlockButton(title: "2 Hours", duration: .twoHours, url: $viewModel.newURL)

                Button("Custom") {
                    showCustomDuration = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newURL.isEmpty)
            }

            // Custom duration picker
            if showCustomDuration && !viewModel.newURL.isEmpty {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hours")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Picker("", selection: $customHours) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text("\(h) hr").tag(h)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 90)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Minutes")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Picker("", selection: $customMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { m in
                                    Text("\(m) min").tag(m)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 90)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }

                        Spacer()
                    }

                    Divider()

                    HStack {
                        Button("Cancel") {
                            showCustomDuration = false
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Text("Block for:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(customHours)h \(customMinutes)m")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)

                        Button("Block") {
                            let duration = TimeInterval(customHours * 3600 + customMinutes * 60)
                            if duration > 0 {
                                _ = BlockingService.shared.activateBlock(url: viewModel.newURL, duration: duration)
                                viewModel.newURL = ""
                            }
                            showCustomDuration = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(customHours == 0 && customMinutes == 0)
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
    }

    // MARK: - Schedules Tab

    private var schedulesTab: some View {
        ScheduleView()
            .frame(maxHeight: 350)
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        SettingsView()
            .frame(maxHeight: 350)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var helperInstalled = HelperClient.shared.isInstalled
    @State private var isInstallingHelper = false
    @State private var morningPromptEnabled = true
    @State private var morningPromptHour = 9
    @State private var frictionDelaySeconds: Int16 = 10
    @State private var showShameStats = true
    @State private var isLoaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)

                // Launch at Login Card
                SettingsCard(
                    icon: "power.circle.fill",
                    iconColor: .blue,
                    title: "Launch at Login",
                    subtitle: "Start FocusGuard when you log in"
                ) {
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.85)
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(enabled: newValue)
                        }
                }

                // Morning Prompt Card
                SettingsCard(
                    icon: "sun.horizon.fill",
                    iconColor: .orange,
                    title: "Morning Prompt",
                    subtitle: "Daily productivity reminder"
                ) {
                    Toggle("", isOn: $morningPromptEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.85)
                        .onChange(of: morningPromptEnabled) { _, _ in saveSettings() }
                }

                // Time picker (shown when morning prompt enabled)
                if morningPromptEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange.opacity(0.7))
                            .frame(width: 20)

                        Text("Prompt at")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $morningPromptHour) {
                            ForEach(5..<12, id: \.self) { h in
                                Text("\(h):00 AM").tag(h)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 100)
                        .onChange(of: morningPromptHour) { _, _ in saveSettings() }

                        Spacer()

                        Button(action: {
                            NotificationService.shared.testNotificationWithFeedback()
                        }) {
                            Text("Test")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.05))
                    )
                }

                // Friction Delay Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)

                            Image(systemName: "hourglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Friction Delay")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Countdown before removing blocks")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // Delay options
                    HStack(spacing: 8) {
                        ForEach([5, 10, 30], id: \.self) { seconds in
                            DelayOptionButton(
                                seconds: seconds,
                                isSelected: frictionDelaySeconds == Int16(seconds),
                                action: {
                                    frictionDelaySeconds = Int16(seconds)
                                    saveSettings()
                                }
                            )
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.purple.opacity(0.6))
                        Text("+ Type confirmation phrase to disable")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

                // Shame Stats Card
                SettingsCard(
                    icon: "chart.bar.fill",
                    iconColor: .red,
                    title: "Show Stats",
                    subtitle: "Display bypass & wasted time stats"
                ) {
                    Toggle("", isOn: $showShameStats)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.85)
                        .onChange(of: showShameStats) { _, _ in saveSettings() }
                }

                Spacer(minLength: 8)

                // Footer
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green.opacity(0.7))
                    Text("Settings saved automatically")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        guard !isLoaded else { return }

        let settings = DataService.shared.getSettings()
        morningPromptEnabled = settings.morningPromptEnabled
        morningPromptHour = Int(settings.morningPromptHour)
        frictionDelaySeconds = settings.frictionDelaySeconds
        showShameStats = settings.showShameStats

        // Set isLoaded AFTER all values are set to prevent onChange from saving
        DispatchQueue.main.async {
            self.isLoaded = true
        }
    }

    private func saveSettings() {
        guard isLoaded else { return } // Don't save during initial load

        DataService.shared.updateSettings { settings in
            settings.morningPromptEnabled = morningPromptEnabled
            settings.morningPromptHour = Int16(morningPromptHour)
            settings.frictionDelaySeconds = frictionDelaySeconds
            settings.showShameStats = showShameStats
        }
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                print("✅ Launch at login enabled")
            } else {
                try SMAppService.mainApp.unregister()
                print("✅ Launch at login disabled")
            }
        } catch {
            print("❌ Failed to toggle launch at login: \(error)")
            // Revert the toggle if it failed
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func installHelper() {
        isInstallingHelper = true

        HelperClient.shared.installHelper { success, error in
            isInstallingHelper = false
            if success {
                helperInstalled = true
            } else if let error = error {
                // Show error alert
                let alert = NSAlert()
                alert.messageText = "Helper Installation Failed"
                alert.informativeText = error
                alert.runModal()
            }
        }
    }
}

// MARK: - Settings Card Component

struct SettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Delay Option Button

struct DelayOptionButton: View {
    let seconds: Int
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("\(seconds)s")
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.purple : (isHovered ? Color.purple.opacity(0.1) : Color.gray.opacity(0.1)))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : (isHovered ? .purple : .secondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.purple : (isHovered ? Color.purple.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct BlockRowView: View {
    let block: WebsiteBlock
    let onRemove: () -> Void
    @State private var isHovered = false

    private var accentColor: Color {
        block.isScheduled ? .purple : .red
    }

    var body: some View {
        HStack(spacing: 12) {
            // Website icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: block.isScheduled ? "calendar.badge.clock" : "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(block.url)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if block.isScheduled {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.system(size: 9, weight: .bold))
                            Text("SCHEDULED")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .medium))
                        Text(block.remainingTimeString)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isHovered ? .red : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(block.isScheduled
                    ? Color.purple.opacity(0.06)
                    : Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(block.isScheduled ? Color.purple.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: block.isScheduled ? 1.5 : 1)
        )
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let isWarning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isWarning ? color : .primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isWarning ? color.opacity(0.08) : Color.clear)
        )
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .orange

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QuickBlockButton: View {
    let title: String
    let duration: TimeInterval
    @Binding var url: String
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            guard !url.isEmpty else { return }
            _ = BlockingService.shared.activateBlock(url: url, duration: duration)
            url = ""
        }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(url.isEmpty ? Color.gray : (isHovered ? Color.blue.opacity(0.8) : Color.blue))
                )
        }
        .buttonStyle(.plain)
        .disabled(url.isEmpty)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - ViewModel

class MenuBarViewModel: ObservableObject {
    @Published var activeBlocks: [WebsiteBlock] = []
    @Published var todayStats: InterventionStats
    @Published var newURL: String = ""

    init() {
        self.todayStats = DataService.shared.getTodayStats()
        refresh()
        setupObservers()
    }

    func refresh() {
        activeBlocks = DataService.shared.getActiveBlocks()
        todayStats = DataService.shared.getTodayStats()
    }

    func addBlock() {
        guard !newURL.isEmpty else { return }
        _ = BlockingService.shared.activateBlock(url: newURL, duration: nil)
        newURL = ""
        refresh()
    }

    func removeBlock(_ block: WebsiteBlock) {
        _ = BlockingService.shared.deactivateBlock(block)
        refresh()
    }

    func removeBlockWithFriction(_ block: WebsiteBlock) {
        // Show friction delay window
        FrictionDelayWindowController.shared.showFrictionDelay(
            for: block,
            onCancel: {
                // User cancelled, do nothing
            },
            onConfirm: { [weak self] in
                // User confirmed after countdown + typing phrase
                _ = BlockingService.shared.deactivateBlock(block)

                // Log bypass event
                DataService.shared.logBypass(url: block.url, bypassType: "friction_override")

                self?.refresh()
            }
        )
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .blocksDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        NotificationCenter.default.addObserver(
            forName: .statsDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }
}
