//
//  DataService.swift
//  FocusGuard
//
//  Core Data management service (singleton)
//

import Foundation
import CoreData

class DataService {
    static let shared = DataService()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FocusGuard")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func initialize() {
        // Ensure Core Data is loaded
        _ = persistentContainer
        print("Core Data initialized")
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }

    // MARK: - Website Blocks

    func createBlock(url: String, duration: TimeInterval?) -> WebsiteBlock {
        let block = WebsiteBlock(context: context, url: url, duration: duration)
        save()
        NotificationCenter.default.post(name: .blocksDidChange, object: nil)
        return block
    }

    func createScheduledBlock(url: String, schedule: BlockSchedule) -> WebsiteBlock {
        let block = WebsiteBlock(context: context, url: url, duration: nil, isScheduled: true, scheduleId: schedule.id)
        save()
        NotificationCenter.default.post(name: .blocksDidChange, object: nil)
        return block
    }

    func deactivateBlock(_ block: WebsiteBlock) {
        block.isActive = false
        save()
        NotificationCenter.default.post(name: .blocksDidChange, object: nil)
    }

    func deleteBlock(_ block: WebsiteBlock) {
        context.delete(block)
        save()
        NotificationCenter.default.post(name: .blocksDidChange, object: nil)
    }

    func getActiveBlocks() -> [WebsiteBlock] {
        return WebsiteBlock.getActiveBlocks(context: context)
    }

    func getActiveBlocksCount() -> Int {
        return getActiveBlocks().count
    }

    func getExpiredBlocks() -> [WebsiteBlock] {
        return WebsiteBlock.getExpiredBlocks(context: context)
    }

    func isURLBlocked(_ url: String) -> Bool {
        let activeBlocks = getActiveBlocks()
        let cleanURL = url.lowercased().replacingOccurrences(of: "www.", with: "")
        return activeBlocks.contains { block in
            let blockURL = block.url.lowercased().replacingOccurrences(of: "www.", with: "")
            return cleanURL.contains(blockURL) || blockURL.contains(cleanURL)
        }
    }

    // MARK: - Block Schedules

    func createSchedule(url: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, days: [Bool]) -> BlockSchedule {
        let schedule = BlockSchedule(context: context)
        schedule.id = UUID()
        schedule.url = url.lowercased()
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

        save()
        return schedule
    }

    func getActiveSchedules() -> [BlockSchedule] {
        return BlockSchedule.getActiveSchedules(context: context)
    }

    func getAllSchedules() -> [BlockSchedule] {
        let request: NSFetchRequest<BlockSchedule> = BlockSchedule.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching schedules: \(error)")
            return []
        }
    }

    func deleteSchedule(_ schedule: BlockSchedule) {
        context.delete(schedule)
        save()
    }

    // MARK: - Bypass Events

    func logBypass(url: String, bypassType: String, reasonGiven: String? = nil) {
        let bypass = BypassEvent(context: context, url: url, bypassType: bypassType, reasonGiven: reasonGiven)
        save()

        // Update today's stats
        let stats = getTodayStats()
        stats.incrementBypass()
        save()

        NotificationCenter.default.post(name: .bypassEventOccurred, object: nil)
        NotificationCenter.default.post(name: .statsDidUpdate, object: nil)
    }

    func getTodayBypassCount() -> Int {
        return BypassEvent.getTodayCount(context: context)
    }

    func getWeekBypassCount() -> Int {
        return BypassEvent.getWeekCount(context: context)
    }

    // MARK: - Usage Sessions

    func logUsage(url: String, durationSeconds: Int, wasBlocked: Bool = false) {
        let session = UsageSession(context: context, url: url, durationSeconds: durationSeconds, wasBlocked: wasBlocked)
        save()

        // Update today's stats
        let stats = getTodayStats()
        if !wasBlocked {
            stats.addWastedTime(minutes: durationSeconds / 60)
            save()
        }

        NotificationCenter.default.post(name: .statsDidUpdate, object: nil)
    }

    func getTodayUsage(for url: String) -> Int {
        return UsageSession.getTodayUsage(for: url, context: context)
    }

    func getAllTodayUsage() -> [String: Int] {
        return UsageSession.getTotalTodayUsage(context: context)
    }

    // MARK: - Intervention Stats

    func getTodayStats() -> InterventionStats {
        return InterventionStats.getTodayStats(context: context)
    }

    func getWeekStats() -> [InterventionStats] {
        return InterventionStats.getWeekStats(context: context)
    }

    // MARK: - App Settings

    func getSettings() -> AppSettings {
        return AppSettings.getSettings(context: context)
    }

    func updateSettings(_ update: (AppSettings) -> Void) {
        let settings = getSettings()
        update(settings)
        save()
    }
}
