//
//  BlockingService.swift
//  FocusGuard
//
//  Orchestrates website blocking operations
//

import Foundation

class BlockingService {
    static let shared = BlockingService()

    private var expirationTimer: Timer?

    private init() {}

    // MARK: - Lifecycle

    func startMonitoring() {
        // Check for expired blocks every minute
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkExpiredBlocks()
        }

        // Apply active blocks on startup
        applyAllActiveBlocks()

        // Note: ScheduleManager handles scheduled blocks, not BlockingService

        print("✅ BlockingService monitoring started")
    }

    func cleanup() {
        expirationTimer?.invalidate()
        // Note: We don't remove blocks on cleanup - they persist
        print("BlockingService cleanup completed")
    }

    // MARK: - Block Operations

    func activateBlock(url: String, duration: TimeInterval?) -> Bool {
        // Create block in database
        let block = DataService.shared.createBlock(url: url, duration: duration)

        // Apply to hosts file
        if HostsFileManager.shared.blockURL(url) {
            print("✅ Block activated for \(url)")

            // Update stats
            let stats = DataService.shared.getTodayStats()
            stats.incrementBlockActivation()
            DataService.shared.save()

            return true
        } else {
            // Failed to apply, deactivate block
            DataService.shared.deactivateBlock(block)
            print("❌ Failed to activate block for \(url)")
            return false
        }
    }

    func deactivateBlock(_ block: WebsiteBlock) -> Bool {
        // Remove from hosts file
        if HostsFileManager.shared.unblockURL(block.url) {
            // Mark as inactive in database
            DataService.shared.deactivateBlock(block)
            print("✅ Block deactivated for \(block.url)")
            return true
        } else {
            print("❌ Failed to deactivate block for \(block.url)")
            return false
        }
    }

    func toggleBlock(url: String, duration: TimeInterval?) -> Bool {
        // Check if already blocked
        if DataService.shared.isURLBlocked(url) {
            // Find and deactivate existing block
            let activeBlocks = DataService.shared.getActiveBlocks()
            if let block = activeBlocks.first(where: { $0.url == url }) {
                return deactivateBlock(block)
            }
            return false
        } else {
            // Activate new block
            return activateBlock(url: url, duration: duration)
        }
    }

    // MARK: - Expiration Management

    func checkExpiredBlocks() {
        let expiredBlocks = DataService.shared.getExpiredBlocks()

        for block in expiredBlocks {
            if !block.isScheduled {
                // Deactivate expired block
                _ = deactivateBlock(block)
                print("⏰ Block expired for \(block.url)")
            } else {
                // Check if schedule is still active
                let activeSchedules = DataService.shared.getActiveSchedules()
                let scheduleStillActive = activeSchedules.contains { $0.id == block.scheduleId }

                if !scheduleStillActive {
                    _ = deactivateBlock(block)
                    print("⏰ Scheduled block expired for \(block.url)")
                }
            }
        }
        // Note: ScheduleManager handles scheduled block creation, not us
    }

    // MARK: - Bulk Operations

    private func applyAllActiveBlocks() {
        let activeBlocks = DataService.shared.getActiveBlocks()

        for block in activeBlocks {
            // Re-apply active blocks to hosts file
            if !HostsFileManager.shared.blockURL(block.url) {
                print("⚠️ Failed to re-apply block for \(block.url)")
            }
        }

        if !activeBlocks.isEmpty {
            print("✅ Re-applied \(activeBlocks.count) active blocks")
        }
    }

    func removeAllBlocks() {
        let activeBlocks = DataService.shared.getActiveBlocks()

        for block in activeBlocks {
            _ = deactivateBlock(block)
        }

        // Also remove from hosts file
        HostsFileManager.shared.removeAllFocusGuardEntries()

        print("🗑️ All blocks removed")
    }

    // MARK: - Query

    func isURLBlocked(_ url: String) -> Bool {
        return DataService.shared.isURLBlocked(url)
    }

    func getActiveBlocks() -> [WebsiteBlock] {
        return DataService.shared.getActiveBlocks()
    }
}

// MARK: - Convenience TimeInterval Extensions

extension TimeInterval {
    static let oneHour: TimeInterval = 3600
    static let fourHours: TimeInterval = 3600 * 4
    static let restOfDay: TimeInterval = {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(86400)  // Next midnight
        return endOfDay.timeIntervalSince(now)
    }()
}
