//
//  ScheduleManager.swift
//  FocusGuard
//
//  Manages scheduled auto-blocking
//

import Foundation
import CoreData

class ScheduleManager {
    static let shared = ScheduleManager()

    private var scheduleTimer: Timer?
    private var activeScheduledBlocks: [UUID: WebsiteBlock] = [:]
    private var failedActivations: Set<UUID> = [] // Track failed activations to avoid retrying

    private init() {}

    // MARK: - Lifecycle

    func startMonitoring() {
        // Check schedules every minute
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }

        // Run immediately on start
        checkSchedules()

        print("ScheduleManager monitoring started")
    }

    func stopMonitoring() {
        scheduleTimer?.invalidate()
        scheduleTimer = nil
    }

    // MARK: - Schedule Checking

    func checkSchedules() {
        let allSchedules = DataService.shared.getAllSchedules()
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute

        for schedule in allSchedules {
            guard schedule.isEnabled, let scheduleId = schedule.id else { continue }

            let isActiveDay = isDayActive(schedule: schedule, weekday: currentWeekday)

            if isActiveDay {
                let startTimeMinutes = Int(schedule.startHour) * 60 + Int(schedule.startMinute)
                let endTimeMinutes = Int(schedule.endHour) * 60 + Int(schedule.endMinute)

                let shouldBeActive = currentTimeMinutes >= startTimeMinutes && currentTimeMinutes < endTimeMinutes
                let isCurrentlyActive = activeScheduledBlocks[scheduleId] != nil

                if shouldBeActive && !isCurrentlyActive {
                    // Only try to activate if we haven't already failed this session
                    if !failedActivations.contains(scheduleId) {
                        // Check if already blocked in hosts file to avoid unnecessary password prompts
                        let blockedURLs = HostsFileManager.shared.getBlockedURLs()
                        if blockedURLs.contains(schedule.url) || blockedURLs.contains("www.\(schedule.url)") {
                            // Already blocked, just track it without prompting
                            let block = DataService.shared.createScheduledBlock(url: schedule.url, schedule: schedule)
                            activeScheduledBlocks[scheduleId] = block

                            // Update stats for scheduled block
                            let stats = DataService.shared.getTodayStats()
                            stats.incrementBlockActivation()
                            DataService.shared.save()

                            print("Scheduled block already active in hosts: \(schedule.url)")
                        } else {
                            activateScheduledBlock(schedule: schedule)
                        }
                    }
                } else if !shouldBeActive && isCurrentlyActive {
                    deactivateScheduledBlock(schedule: schedule)
                    // Clear failed status when time window ends
                    failedActivations.remove(scheduleId)
                } else if !shouldBeActive {
                    // Clear failed status when outside time window
                    failedActivations.remove(scheduleId)
                }
            } else {
                if activeScheduledBlocks[scheduleId] != nil {
                    deactivateScheduledBlock(schedule: schedule)
                }
            }
        }
    }

    private func isDayActive(schedule: BlockSchedule, weekday: Int) -> Bool {
        switch weekday {
        case 1: return schedule.sunday
        case 2: return schedule.monday
        case 3: return schedule.tuesday
        case 4: return schedule.wednesday
        case 5: return schedule.thursday
        case 6: return schedule.friday
        case 7: return schedule.saturday
        default: return false
        }
    }

    private func activateScheduledBlock(schedule: BlockSchedule) {
        guard let scheduleId = schedule.id else { return }

        let calendar = Calendar.current
        var endComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        endComponents.hour = Int(schedule.endHour)
        endComponents.minute = Int(schedule.endMinute)

        guard let endTime = calendar.date(from: endComponents) else { return }
        let duration = endTime.timeIntervalSinceNow

        guard duration > 0 else { return }

        let block = DataService.shared.createScheduledBlock(url: schedule.url, schedule: schedule)
        activeScheduledBlocks[scheduleId] = block

        if HostsFileManager.shared.blockURL(schedule.url) {
            // Update stats for scheduled block
            let stats = DataService.shared.getTodayStats()
            stats.incrementBlockActivation()
            DataService.shared.save()

            print("Scheduled block activated: \(schedule.url) until \(schedule.endHour):\(String(format: "%02d", schedule.endMinute))")
            NotificationCenter.default.post(name: .scheduledBlockActivated, object: schedule)
        } else {
            print("Failed to activate scheduled block for \(schedule.url) - will not retry this session")
            DataService.shared.deactivateBlock(block)
            activeScheduledBlocks.removeValue(forKey: scheduleId)
            // Mark as failed so we don't keep prompting for password
            failedActivations.insert(scheduleId)
        }
    }

    private func deactivateScheduledBlock(schedule: BlockSchedule) {
        guard let scheduleId = schedule.id,
              let block = activeScheduledBlocks[scheduleId] else { return }

        if HostsFileManager.shared.unblockURL(schedule.url) {
            DataService.shared.deactivateBlock(block)
            activeScheduledBlocks.removeValue(forKey: scheduleId)
            print("Scheduled block deactivated: \(schedule.url)")
            NotificationCenter.default.post(name: .scheduledBlockDeactivated, object: schedule)
        }
    }

    // MARK: - Schedule Management

    func createSchedule(url: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, days: [Bool]) -> BlockSchedule {
        let context = DataService.shared.context
        let schedule = BlockSchedule(context: context)
        schedule.id = UUID()
        schedule.url = url.lowercased().replacingOccurrences(of: "www.", with: "")
        schedule.startHour = Int16(startHour)
        schedule.startMinute = Int16(startMinute)
        schedule.endHour = Int16(endHour)
        schedule.endMinute = Int16(endMinute)
        schedule.isEnabled = true
        schedule.createdAt = Date()

        if days.count >= 7 {
            schedule.sunday = days[0]
            schedule.monday = days[1]
            schedule.tuesday = days[2]
            schedule.wednesday = days[3]
            schedule.thursday = days[4]
            schedule.friday = days[5]
            schedule.saturday = days[6]
        }

        DataService.shared.save()
        checkSchedules()

        return schedule
    }

    func deleteSchedule(_ schedule: BlockSchedule) {
        if let scheduleId = schedule.id, activeScheduledBlocks[scheduleId] != nil {
            deactivateScheduledBlock(schedule: schedule)
        }
        DataService.shared.deleteSchedule(schedule)
    }

    func toggleSchedule(_ schedule: BlockSchedule) {
        schedule.isEnabled.toggle()
        DataService.shared.save()

        if !schedule.isEnabled {
            if let scheduleId = schedule.id, activeScheduledBlocks[scheduleId] != nil {
                deactivateScheduledBlock(schedule: schedule)
            }
        } else {
            checkSchedules()
        }
    }

    // MARK: - Query

    func getActiveScheduledBlocks() -> [WebsiteBlock] {
        return Array(activeScheduledBlocks.values)
    }

    func isScheduleActive(_ schedule: BlockSchedule) -> Bool {
        guard let scheduleId = schedule.id else { return false }
        return activeScheduledBlocks[scheduleId] != nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let scheduledBlockActivated = Notification.Name("scheduledBlockActivated")
    static let scheduledBlockDeactivated = Notification.Name("scheduledBlockDeactivated")
}
