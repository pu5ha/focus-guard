//
//  NotificationService.swift
//  FocusGuard
//
//  Manages macOS notifications including morning productivity prompt
//

import Foundation
import UserNotifications
import AppKit

class NotificationService: NSObject {
    static let shared = NotificationService()

    private var morningPromptTimer: Timer?

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }

        // Set delegate for handling actions
        UNUserNotificationCenter.current().delegate = self
    }

    func setupNotificationCategories() {
        // Morning prompt category with actions
        let blockUntil6PM = UNNotificationAction(
            identifier: "BLOCK_UNTIL_6PM",
            title: "Block until 6 PM",
            options: [.foreground]
        )

        let blockUntil9PM = UNNotificationAction(
            identifier: "BLOCK_UNTIL_9PM",
            title: "Block until 9 PM",
            options: [.foreground]
        )

        let skipToday = UNNotificationAction(
            identifier: "SKIP_TODAY",
            title: "Skip today",
            options: [.destructive]
        )

        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_PROMPT",
            actions: [blockUntil6PM, blockUntil9PM, skipToday],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([morningCategory])
    }

    // MARK: - Morning Prompt

    func startMorningPromptMonitoring() {
        // Check every minute if it's time for the morning prompt
        morningPromptTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkMorningPrompt()
        }

        print("✅ Morning prompt monitoring started")
    }

    func stopMorningPromptMonitoring() {
        morningPromptTimer?.invalidate()
        morningPromptTimer = nil
    }

    private func checkMorningPrompt() {
        let settings = DataService.shared.getSettings()

        guard settings.morningPromptEnabled else { return }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // Check if it's the right time (within the minute)
        if currentHour == settings.morningPromptHour && currentMinute == settings.morningPromptMinute {
            // Check if we already sent today's prompt
            let today = calendar.startOfDay(for: now)
            let lastPromptKey = "lastMorningPrompt"

            if let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date {
                let lastPromptDay = calendar.startOfDay(for: lastPrompt)
                if lastPromptDay == today {
                    return // Already sent today
                }
            }

            // Send the prompt
            sendMorningPrompt()

            // Record that we sent it
            UserDefaults.standard.set(now, forKey: lastPromptKey)
        }
    }

    func sendMorningPrompt() {
        // Ensure delegate is set for foreground notifications
        UNUserNotificationCenter.current().delegate = self

        let content = UNMutableNotificationContent()
        content.title = "Start Your Day Right"
        content.body = "Block distractions and focus on what matters. Your future self will thank you."
        content.sound = .default
        content.categoryIdentifier = "MORNING_PROMPT"

        let request = UNNotificationRequest(
            identifier: "morning-prompt-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send morning prompt: \(error)")
            } else {
                print("✅ Morning prompt sent successfully!")
            }
        }
    }

    func testNotificationWithFeedback() {
        sendMorningPrompt()

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Notification Sent"
            alert.informativeText = "A test notification was sent to your Notification Center. Click the date/time in your menu bar to view it."
            alert.runModal()
        }
    }

    // MARK: - General Notifications

    func sendBlockExpiredNotification(url: String) {
        let content = UNMutableNotificationContent()
        content.title = "Block Expired"
        content.body = "The block on \(url) has expired."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "block-expired-\(url)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendScheduledBlockNotification(url: String, isActivating: Bool) {
        let content = UNMutableNotificationContent()

        if isActivating {
            content.title = "Scheduled Block Active"
            content.body = "\(url) is now blocked according to your schedule."
        } else {
            content.title = "Scheduled Block Ended"
            content.body = "\(url) is no longer blocked. Schedule ended."
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "scheduled-block-\(url)-\(isActivating)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendBypassWarningNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bypass Warning"
        content.body = "You've bypassed FocusGuard \(count) times today. Stay strong!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "bypass-warning",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "BLOCK_UNTIL_6PM":
            handleBlockUntil(hour: 18)
        case "BLOCK_UNTIL_9PM":
            handleBlockUntil(hour: 21)
        case "SKIP_TODAY":
            print("User skipped morning prompt")
        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    private func handleBlockUntil(hour: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0

        guard let endTime = calendar.date(from: components) else { return }
        let duration = endTime.timeIntervalSinceNow

        guard duration > 0 else { return }

        // Get default blocked sites and block them
        let defaultSites = ["x.com", "twitter.com", "reddit.com", "instagram.com", "facebook.com"]

        for site in defaultSites {
            _ = BlockingService.shared.activateBlock(url: site, duration: duration)
        }

        print("✅ Blocked distractions until \(hour):00")
    }
}
