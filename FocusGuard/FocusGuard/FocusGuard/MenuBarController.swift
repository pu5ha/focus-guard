//
//  MenuBarController.swift
//  FocusGuard
//
//  Manages the menu bar item and updates its appearance based on app state
//

import AppKit
import Combine

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    @Published var bypassCount: Int = 0
    @Published var activeBlocksCount: Int = 0

    init(statusItem: NSStatusItem?) {
        self.statusItem = statusItem
        setupObservers()
        updateMenuBarTitle()
    }

    private func setupObservers() {
        // Observe block changes
        NotificationCenter.default.publisher(for: .blocksDidChange)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &cancellables)

        // Observe bypass events
        NotificationCenter.default.publisher(for: .bypassEventOccurred)
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &cancellables)

        // Update every minute to refresh time-based stats
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &cancellables)
    }

    func updateMenuBarTitle() {
        guard let button = statusItem?.button else { return }

        // Get today's stats
        let stats = DataService.shared.getTodayStats()
        bypassCount = Int(stats.bypassCount)
        activeBlocksCount = DataService.shared.getActiveBlocksCount()

        // Update button title based on configuration
        // Always show bypass count (user preference: maximum visibility)
        if stats.bypassCount > 0 {
            let wastedMinutes = stats.totalWastedMinutes
            button.title = " ⚠️ \(stats.bypassCount) bypasses | ⏱️ \(wastedMinutes)m"

            // Flash menu bar if bypasses >= 5
            if stats.bypassCount >= 5 {
                flashMenuBar()
            }
        } else if activeBlocksCount > 0 {
            button.title = " 🛡️ \(activeBlocksCount) active"
        } else {
            button.title = " 🛡️"
        }
    }

    private func flashMenuBar() {
        // Brief highlight animation
        guard let button = statusItem?.button else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            button.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.3).cgColor
        }) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                button.layer?.backgroundColor = NSColor.clear.cgColor
            })
        }
    }
}

// Notification names
extension Notification.Name {
    static let blocksDidChange = Notification.Name("blocksDidChange")
    static let bypassEventOccurred = Notification.Name("bypassEventOccurred")
    static let statsDidUpdate = Notification.Name("statsDidUpdate")
}
