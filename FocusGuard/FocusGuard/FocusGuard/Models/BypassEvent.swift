//
//  BypassEvent.swift
//  FocusGuard
//
//  Tracks every time user bypasses an intervention
//

import Foundation
import CoreData

@objc(BypassEvent)
public class BypassEvent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var url: String
    @NSManaged public var bypassType: String  // "intervention_page", "disabled_block"
    @NSManaged public var timestamp: Date
    @NSManaged public var reasonGiven: String?

    convenience init(context: NSManagedObjectContext, url: String, bypassType: String, reasonGiven: String? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.url = url.lowercased()
        self.bypassType = bypassType
        self.timestamp = Date()
        self.reasonGiven = reasonGiven
    }
}

extension BypassEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BypassEvent> {
        return NSFetchRequest<BypassEvent>(entityName: "BypassEvent")
    }

    static func getTodayCount(context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let request: NSFetchRequest<BypassEvent> = BypassEvent.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)

        do {
            return try context.count(for: request)
        } catch {
            print("Error counting today's bypasses: \(error)")
            return 0
        }
    }

    static func getWeekCount(context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let request: NSFetchRequest<BypassEvent> = BypassEvent.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", weekAgo as NSDate)

        do {
            return try context.count(for: request)
        } catch {
            print("Error counting week's bypasses: \(error)")
            return 0
        }
    }
}
