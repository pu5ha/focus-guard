//
//  BlockSchedule.swift
//  FocusGuard
//
//  Core Data model for scheduled blocks (auto-blocking)
//

import Foundation
import CoreData

@objc(BlockSchedule)
public class BlockSchedule: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var url: String
    @NSManaged public var isEnabled: Bool
    @NSManaged public var startHour: Int16
    @NSManaged public var startMinute: Int16
    @NSManaged public var endHour: Int16
    @NSManaged public var endMinute: Int16
    @NSManaged public var monday: Bool
    @NSManaged public var tuesday: Bool
    @NSManaged public var wednesday: Bool
    @NSManaged public var thursday: Bool
    @NSManaged public var friday: Bool
    @NSManaged public var saturday: Bool
    @NSManaged public var sunday: Bool
    @NSManaged public var createdAt: Date

    var isActiveNow: Bool {
        guard isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)

        // Check if today is in the schedule
        guard isDayActive(weekday: weekday) else { return false }

        // Get current time
        let nowHour = calendar.component(.hour, from: now)
        let nowMinute = calendar.component(.minute, from: now)
        let nowMinutes = nowHour * 60 + nowMinute
        let startMinutes = Int(startHour) * 60 + Int(startMinute)
        let endMinutes = Int(endHour) * 60 + Int(endMinute)

        return nowMinutes >= startMinutes && nowMinutes < endMinutes
    }

    func isDayActive(weekday: Int) -> Bool {
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: return false
        }
    }

    var daysString: String {
        var days: [String] = []
        if sunday { days.append("Sun") }
        if monday { days.append("Mon") }
        if tuesday { days.append("Tue") }
        if wednesday { days.append("Wed") }
        if thursday { days.append("Thu") }
        if friday { days.append("Fri") }
        if saturday { days.append("Sat") }
        return days.joined(separator: ", ")
    }

    var timeString: String {
        let startH = startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour)
        let endH = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour)
        let startAMPM = startHour >= 12 ? "PM" : "AM"
        let endAMPM = endHour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@ - %d:%02d %@", startH, startMinute, startAMPM, endH, endMinute, endAMPM)
    }
}

extension BlockSchedule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockSchedule> {
        return NSFetchRequest<BlockSchedule>(entityName: "BlockSchedule")
    }

    static func getActiveSchedules(context: NSManagedObjectContext) -> [BlockSchedule] {
        let request: NSFetchRequest<BlockSchedule> = BlockSchedule.fetchRequest()
        request.predicate = NSPredicate(format: "isEnabled == YES")

        do {
            return try context.fetch(request).filter { $0.isActiveNow }
        } catch {
            print("Error fetching active schedules: \(error)")
            return []
        }
    }
}
