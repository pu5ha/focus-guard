//
//  InterventionStats.swift
//  FocusGuard
//
//  Daily statistics for shame stats display
//

import Foundation
import CoreData

@objc(InterventionStats)
public class InterventionStats: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date
    @NSManaged public var bypassCount: Int32
    @NSManaged public var blockCount: Int32
    @NSManaged public var totalTimeWastedSeconds: Int32
    @NSManaged public var streakDays: Int32

    // Computed property for backwards compatibility
    var blocksActivated: Int {
        get { Int(blockCount) }
        set { blockCount = Int32(newValue) }
    }

    var totalWastedMinutes: Int {
        get { Int(totalTimeWastedSeconds / 60) }
        set { totalTimeWastedSeconds = Int32(newValue * 60) }
    }

    func incrementBypass() {
        bypassCount += 1
    }

    func incrementBlockActivation() {
        blockCount += 1
    }

    func addWastedTime(minutes: Int) {
        totalTimeWastedSeconds += Int32(minutes * 60)
    }
}

extension InterventionStats {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InterventionStats> {
        return NSFetchRequest<InterventionStats>(entityName: "InterventionStats")
    }

    static func getTodayStats(context: NSManagedObjectContext) -> InterventionStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let request: NSFetchRequest<InterventionStats> = InterventionStats.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        request.fetchLimit = 1

        do {
            if let stats = try context.fetch(request).first {
                return stats
            } else {
                // Create new stats for today
                let entity = NSEntityDescription.entity(forEntityName: "InterventionStats", in: context)!
                let newStats = InterventionStats(entity: entity, insertInto: context)
                newStats.id = UUID()
                newStats.date = today
                newStats.bypassCount = 0
                newStats.blockCount = 0
                newStats.totalTimeWastedSeconds = 0
                newStats.streakDays = 0
                try context.save()
                return newStats
            }
        } catch {
            print("Error fetching today's stats: \(error)")
            // Return temporary stats
            let entity = NSEntityDescription.entity(forEntityName: "InterventionStats", in: context)!
            let tempStats = InterventionStats(entity: entity, insertInto: nil)
            tempStats.date = today
            tempStats.bypassCount = 0
            tempStats.blockCount = 0
            tempStats.totalTimeWastedSeconds = 0
            tempStats.streakDays = 0
            return tempStats
        }
    }

    static func getWeekStats(context: NSManagedObjectContext) -> [InterventionStats] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let request: NSFetchRequest<InterventionStats> = InterventionStats.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", weekAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InterventionStats.date, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching week stats: \(error)")
            return []
        }
    }
}
