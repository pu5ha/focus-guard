//
//  AppSettings.swift
//  FocusGuard
//
//  Application settings (singleton)
//

import Foundation
import CoreData

@objc(AppSettings)
public class AppSettings: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var launchAtLogin: Bool
    @NSManaged public var showNotifications: Bool
    @NSManaged public var morningPromptEnabled: Bool
    @NSManaged public var morningPromptHour: Int16
    @NSManaged public var morningPromptMinute: Int16
    @NSManaged public var frictionDelaySeconds: Int16
    @NSManaged public var requireTypingToDisable: Bool
    @NSManaged public var showShameStats: Bool
}

extension AppSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettings> {
        return NSFetchRequest<AppSettings>(entityName: "AppSettings")
    }

    static func getSettings(context: NSManagedObjectContext) -> AppSettings {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        request.fetchLimit = 1

        do {
            if let settings = try context.fetch(request).first {
                return settings
            } else {
                // Create default settings using entity description
                let entity = NSEntityDescription.entity(forEntityName: "AppSettings", in: context)!
                let settings = AppSettings(entity: entity, insertInto: context)
                settings.id = UUID()
                settings.launchAtLogin = true
                settings.showNotifications = true
                settings.morningPromptEnabled = true
                settings.morningPromptHour = 9
                settings.morningPromptMinute = 0
                settings.frictionDelaySeconds = 10
                settings.requireTypingToDisable = true
                settings.showShameStats = true
                try context.save()
                return settings
            }
        } catch {
            print("Error fetching settings: \(error)")
            // Return a temporary settings object
            let entity = NSEntityDescription.entity(forEntityName: "AppSettings", in: context)!
            let settings = AppSettings(entity: entity, insertInto: nil)
            settings.morningPromptEnabled = true
            settings.morningPromptHour = 9
            settings.frictionDelaySeconds = 10
            settings.showShameStats = true
            return settings
        }
    }

    var morningPromptTimeString: String {
        let hour = morningPromptHour > 12 ? morningPromptHour - 12 : (morningPromptHour == 0 ? 12 : morningPromptHour)
        let ampm = morningPromptHour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", hour, morningPromptMinute, ampm)
    }
}
