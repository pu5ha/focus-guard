//
//  HelperProtocol.swift
//  FocusGuard
//
//  XPC Protocol for communication between app and privileged helper
//

import Foundation

/// The protocol that the helper service will implement
@objc(HelperProtocol)
protocol HelperProtocol {
    /// Block URLs by adding them to /etc/hosts
    func blockURLs(_ urls: [String], withReply reply: @escaping (Bool, String?) -> Void)

    /// Unblock URLs by removing them from /etc/hosts
    func unblockURLs(_ urls: [String], withReply reply: @escaping (Bool, String?) -> Void)

    /// Remove all FocusGuard entries from /etc/hosts
    func removeAllBlocks(withReply reply: @escaping (Bool, String?) -> Void)

    /// Get the helper version (for compatibility checking)
    func getVersion(withReply reply: @escaping (String) -> Void)
}

/// Helper identifiers
struct HelperConstants {
    static let helperBundleID = "com.focusguard.helper"
    static let machServiceName = "com.focusguard.helper"
    static let focusGuardMarker = "# FocusGuard Managed"
    static let hostsFilePath = "/etc/hosts"
}
