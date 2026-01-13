//
//  FocusGuardApp.swift
//  FocusGuard
//
//  Main application entry point for FocusGuard
//  A proactive anti-distraction system for macOS
//
import SwiftUI
import AppKit

@main
struct FocusGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Core Data
        DataService.shared.initialize()

        // Initialize the blocking service
        BlockingService.shared.startMonitoring()

        // Start schedule monitoring
        ScheduleManager.shared.startMonitoring()

        // Setup notifications
        NotificationService.shared.requestPermission()
        NotificationService.shared.setupNotificationCategories()
        NotificationService.shared.startMorningPromptMonitoring()

        // Create the status bar item
        setupMenuBar()

        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: "FocusGuard")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover for menu content
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 550)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())

        // Initialize menu bar controller for dynamic updates
        menuBarController = MenuBarController(statusItem: statusItem!)
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Activate the app when showing popover
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save any pending data
        DataService.shared.save()
    }
}
