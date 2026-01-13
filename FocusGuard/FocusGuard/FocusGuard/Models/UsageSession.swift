//
//  UsageSession.swift
//  FocusGuard
//
//  Tracks time spent on websites
//

import Foundation
import CoreData

@objc(UsageSession)
public class UsageSession: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var url: String
    @NSManaged public var date: Date
    @NSManaged public var durationSeconds: Int
    @NSManaged public var wasBlocked: Bool
    @NSManaged public var timestamp: Date

    convenience init(context: NSManagedObjectContext, url: String, durationSeconds: Int, wasBlocked: Bool = false) {
        self.init(context: context)
        self.id = UUID()
        self.url = url.lowercased()
        self.date = Calendar.current.startOfDay(for: Date())
        self.durationSeconds = durationSeconds
        self.wasBlocked = wasBlocked
        self.timestamp = Date()
    }
}

extension UsageSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsageSession> {
        return NSFetchRequest<UsageSession>(entityName: "UsageSession")
    }

    static func getTodayUsage(for url: String, context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let request: NSFetchRequest<UsageSession> = UsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@ AND timestamp >= %@", url.lowercased(), startOfDay as NSDate)

        do {
            let sessions = try context.fetch(request)
            return sessions.reduce(0) { $0 + $1.durationSeconds }
        } catch {
            print("Error fetching today's usage: \(error)")
            return 0
        }
    }

    static func getTotalTodayUsage(context: NSManagedObjectContext) -> [String: Int] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let request: NSFetchRequest<UsageSession> = UsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)

        do {
            let sessions = try context.fetch(request)
            var usage: [String: Int] = [:]
            for session in sessions {
                usage[session.url, default: 0] += session.durationSeconds
            }
            return usage
        } catch {
            print("Error fetching today's total usage: \(error)")
            return [:]
        }
    }
}
