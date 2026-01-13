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
            Picker("", selection: $selectedTab) {
                Text("Blocks").tag(0)
                Text("Schedules").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
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
        HStack {
            Image(systemName: "shield.fill")
                .foregroundColor(.blue)
            Text("FocusGuard")
                .font(.headline)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // Always visible shame stats
    private var shameStatsBar: some View {
        HStack(spacing: 16) {
            // Bypass count
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(viewModel.todayStats.bypassCount > 0 ? .orange : .gray)
                Text("\(viewModel.todayStats.bypassCount)")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.todayStats.bypassCount > 0 ? .orange : .secondary)
                Text("bypasses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 16)

            // Time wasted
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .foregroundColor(viewModel.todayStats.totalWastedMinutes > 0 ? .red : .gray)
                Text("\(viewModel.todayStats.totalWastedMinutes)m")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.todayStats.totalWastedMinutes > 0 ? .red : .secondary)
                Text("wasted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 16)

            // Blocks activated
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("\(viewModel.todayStats.blocksActivated)")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("blocked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.05))
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
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Active Blocks")
                .font(.headline)

            Text("Add websites below to start blocking distractions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @State private var showCustomDuration = false
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0

    private var quickActionsView: some View {
        VStack(spacing: 8) {
            // URL input
            HStack {
                TextField("Enter website (e.g., x.com)", text: $viewModel.newURL)
                    .textFieldStyle(.roundedBorder)

                Button(action: { viewModel.addBlock() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
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
                VStack(spacing: 8) {
                    HStack {
                        Text("Duration:")
                            .font(.caption)

                        Picker("Hours", selection: $customHours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)h").tag(h)
                            }
                        }
                        .frame(width: 70)

                        Picker("Minutes", selection: $customMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text("\(m)m").tag(m)
                            }
                        }
                        .frame(width: 70)
                    }

                    HStack {
                        Button("Cancel") {
                            showCustomDuration = false
                        }
                        .buttonStyle(.bordered)

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
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
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
            VStack(alignment: .leading, spacing: 16) {
                // Launch at Login
                GroupBox("Startup") {
                    Toggle("Launch FocusGuard at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(enabled: newValue)
                        }
                        .padding(.vertical, 4)
                }

                // Password-Free Mode
                GroupBox("Password-Free Mode") {
                    VStack(alignment: .leading, spacing: 8) {
                        if helperInstalled {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Helper installed - no password needed!")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("Install a helper to block sites without password prompts")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button(action: installHelper) {
                                if isInstallingHelper {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Text("Install Helper")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isInstallingHelper)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Morning Prompt
                GroupBox("Morning Productivity Prompt") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable daily prompt", isOn: $morningPromptEnabled)
                            .onChange(of: morningPromptEnabled) { _, _ in saveSettings() }

                        if morningPromptEnabled {
                            HStack {
                                Text("Prompt time:")
                                Picker("Hour", selection: $morningPromptHour) {
                                    ForEach(5..<12, id: \.self) { h in
                                        Text("\(h) AM").tag(h)
                                    }
                                }
                                .frame(width: 100)
                                .onChange(of: morningPromptHour) { _, _ in saveSettings() }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Friction Delay
                GroupBox("Friction Delay") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Countdown before disabling blocks")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Delay", selection: $frictionDelaySeconds) {
                            Text("5 seconds").tag(Int16(5))
                            Text("10 seconds").tag(Int16(10))
                            Text("30 seconds").tag(Int16(30))
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: frictionDelaySeconds) { _, _ in saveSettings() }

                        Text("+ Required to type confirmation phrase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Shame Stats
                GroupBox("Shame Stats") {
                    Toggle("Always show stats in menu bar", isOn: $showShameStats)
                        .onChange(of: showShameStats) { _, _ in saveSettings() }
                        .padding(.vertical, 4)
                }

                // Test Notifications
                Button("Test Morning Prompt") {
                    NotificationService.shared.testNotificationWithFeedback()
                }
                .buttonStyle(.bordered)

                Text("Settings are saved automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct BlockRowView: View {
    let block: WebsiteBlock
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.url)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if block.isScheduled {
                        Label("Scheduled", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Label(block.remainingTimeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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

    var body: some View {
        Button(title) {
            guard !url.isEmpty else { return }
            _ = BlockingService.shared.activateBlock(url: url, duration: duration)
            url = ""
        }
        .buttonStyle(.borderedProminent)
        .disabled(url.isEmpty)
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
