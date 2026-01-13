//
//  HostsFileManager.swift
//  FocusGuard
//
//  Manages /etc/hosts file modifications for website blocking
//

import Foundation

class HostsFileManager {
    static let shared = HostsFileManager()

    private let hostsFilePath = "/etc/hosts"
    private let backupFilePath = "/tmp/hosts.backup"
    private let focusGuardMarker = "# FocusGuard Managed"

    // Disable helper for now since XPC isn't working properly
    // TODO: Fix XPC helper setup and re-enable
    private var useHelper: Bool {
        return false // HelperClient.shared.isInstalled
    }

    private init() {}

    // MARK: - Public API

    func blockURL(_ url: String) -> Bool {
        let variants = getURLVariants(url)

        if useHelper {
            return blockURLsViaHelper(variants)
        } else {
            return addBlockEntries(variants)
        }
    }

    func unblockURL(_ url: String) -> Bool {
        let variants = getURLVariants(url)

        if useHelper {
            return unblockURLsViaHelper(variants)
        } else {
            return removeBlockEntries(variants)
        }
    }

    // MARK: - Helper-based blocking (no password required)

    private func blockURLsViaHelper(_ urls: [String]) -> Bool {
        var success = false
        let semaphore = DispatchSemaphore(value: 0)

        HelperClient.shared.blockURLs(urls) { result, error in
            if let error = error {
                print("❌ Helper block error: \(error)")
            }
            success = result
            semaphore.signal()
        }

        // Timeout after 5 seconds to prevent freezing
        let result = semaphore.wait(timeout: .now() + 5)
        if result == .timedOut {
            print("❌ Helper block timed out, falling back to AppleScript")
            return addBlockEntries(urls)
        }

        if success {
            print("✅ Blocked via helper: \(urls.joined(separator: ", "))")
        }
        return success
    }

    private func unblockURLsViaHelper(_ urls: [String]) -> Bool {
        var success = false
        let semaphore = DispatchSemaphore(value: 0)

        HelperClient.shared.unblockURLs(urls) { result, error in
            if let error = error {
                print("❌ Helper unblock error: \(error)")
            }
            success = result
            semaphore.signal()
        }

        // Timeout after 5 seconds to prevent freezing
        let result = semaphore.wait(timeout: .now() + 5)
        if result == .timedOut {
            print("❌ Helper unblock timed out, falling back to AppleScript")
            return removeBlockEntries(urls)
        }

        if success {
            print("✅ Unblocked via helper: \(urls.joined(separator: ", "))")
        }
        return success
    }

    // MARK: - AppleScript-based blocking (fallback, requires password)

    func getBlockedURLs() -> [String] {
        guard let content = readHostsFile() else { return [] }

        let lines = content.components(separatedBy: .newlines)
        var blocked: [String] = []

        for line in lines {
            if line.contains(focusGuardMarker) {
                let components = line.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    blocked.append(components[1])
                }
            }
        }

        return blocked
    }

    // MARK: - Private Helpers

    private func getURLVariants(_ url: String) -> [String] {
        var variants: [String] = []
        let cleanURL = url.lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "")

        // Add base domain
        variants.append(cleanURL)

        // Add www variant
        if !cleanURL.hasPrefix("www.") {
            variants.append("www.\(cleanURL)")
        } else {
            variants.append(cleanURL.replacingOccurrences(of: "www.", with: ""))
        }

        // Special case: x.com also block twitter.com
        if cleanURL.contains("x.com") {
            variants.append("twitter.com")
            variants.append("www.twitter.com")
        }

        return Array(Set(variants))  // Remove duplicates
    }

    private func addBlockEntries(_ urls: [String]) -> Bool {
        // Build all new entries
        var newEntries: [String] = []
        for url in urls {
            newEntries.append("127.0.0.1 \(url) \(focusGuardMarker)")
        }
        let entriesToAdd = newEntries.joined(separator: "\\n")

        // Single AppleScript that does everything: backup, append entries, and flush DNS
        let script = """
        do shell script "cp \(hostsFilePath) \(backupFilePath) && echo '\(entriesToAdd)' >> \(hostsFilePath) && dscacheutil -flushcache && killall -HUP mDNSResponder 2>/dev/null || true" with administrator privileges
        """

        if runAppleScript(script) != nil {
            print("✅ Blocked: \(urls.joined(separator: ", "))")
            return true
        } else {
            print("❌ Failed to block URLs")
            return false
        }
    }

    private func removeBlockEntries(_ urls: [String]) -> Bool {
        // Build grep pattern to remove matching lines
        let patterns = urls.map { "-e '\($0)'" }.joined(separator: " ")

        // Single AppleScript: backup, remove matching lines, flush DNS
        let script = """
        do shell script "cp \(hostsFilePath) \(backupFilePath) && grep -v \(patterns) \(hostsFilePath) > /tmp/hosts.new && mv /tmp/hosts.new \(hostsFilePath) && dscacheutil -flushcache && killall -HUP mDNSResponder 2>/dev/null || true" with administrator privileges
        """

        if runAppleScript(script) != nil {
            print("✅ Unblocked: \(urls.joined(separator: ", "))")
            return true
        } else {
            print("❌ Failed to unblock URLs")
            return false
        }
    }

    private func readHostsFile() -> String? {
        // Read without admin privileges first (hosts file is world-readable)
        do {
            return try String(contentsOfFile: hostsFilePath, encoding: .utf8)
        } catch {
            print("❌ Failed to read hosts file: \(error)")
            return nil
        }
    }

    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            print("❌ Failed to create AppleScript")
            return nil
        }

        let output = scriptObject.executeAndReturnError(&error)

        if let error = error {
            print("❌ AppleScript error: \(error)")
            return nil
        }

        return output.stringValue
    }

    // MARK: - Cleanup

    func removeAllFocusGuardEntries() -> Bool {
        if useHelper {
            var success = false
            let semaphore = DispatchSemaphore(value: 0)

            HelperClient.shared.removeAllBlocks { result, error in
                if let error = error {
                    print("❌ Helper remove all error: \(error)")
                }
                success = result
                semaphore.signal()
            }

            semaphore.wait()
            if success {
                print("✅ Removed all FocusGuard entries via helper")
            }
            return success
        }

        // Fallback to AppleScript
        let script = """
        do shell script "cp \(hostsFilePath) \(backupFilePath) && grep -v '\(focusGuardMarker)' \(hostsFilePath) > /tmp/hosts.new && mv /tmp/hosts.new \(hostsFilePath) && dscacheutil -flushcache && killall -HUP mDNSResponder 2>/dev/null || true" with administrator privileges
        """

        if runAppleScript(script) != nil {
            print("✅ Removed all FocusGuard entries from hosts file")
            return true
        }

        return false
    }
}
