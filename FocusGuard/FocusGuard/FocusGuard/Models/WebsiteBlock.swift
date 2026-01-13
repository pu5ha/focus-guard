//
//  WebsiteBlock.swift
//  FocusGuard
//
//  Core Data model for website blocks
//

import Foundation
import CoreData

@objc(WebsiteBlock)
public class WebsiteBlock: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var url: String
    @NSManaged public var isActive: Bool
    @NSManaged public var endTime: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var isScheduled: Bool
    @NSManaged public var scheduleId: UUID?

    // Convenience initializer
    convenience init(context: NSManagedObjectContext, url: String, duration: TimeInterval?, isScheduled: Bool = false, scheduleId: UUID? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.url = url.lowercased()
        self.isActive = true
        self.createdAt = Date()
        self.isScheduled = isScheduled
        self.scheduleId = scheduleId

        if let duration = duration {
            self.endTime = Date().addingTimeInterval(duration)
        }
    }

    var isExpired: Bool {
        guard let endTime = endTime else { return false }
        return Date() > endTime
    }

    var remainingTime: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return max(0, endTime.timeIntervalSinceNow)
    }

    var remainingTimeString: String {
        let remaining = remainingTime
        if remaining == 0 { return "Permanent" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension WebsiteBlock {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WebsiteBlock> {
        return NSFetchRequest<WebsiteBlock>(entityName: "WebsiteBlock")
    }

    static func getActiveBlocks(context: NSManagedObjectContext) -> [WebsiteBlock] {
        let request: NSFetchRequest<WebsiteBlock> = WebsiteBlock.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WebsiteBlock.createdAt, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active blocks: \(error)")
            return []
        }
    }

    static func getExpiredBlocks(context: NSManagedObjectContext) -> [WebsiteBlock] {
        let request: NSFetchRequest<WebsiteBlock> = WebsiteBlock.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES AND endTime != nil AND endTime < %@", Date() as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching expired blocks: \(error)")
            return []
        }
    }
}
