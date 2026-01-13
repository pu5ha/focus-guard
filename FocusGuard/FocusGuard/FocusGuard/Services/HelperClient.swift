//
//  HelperClient.swift
//  FocusGuard
//
//  Client for communicating with the privileged helper via XPC
//

import Foundation
import ServiceManagement

class HelperClient {
    static let shared = HelperClient()

    private var connection: NSXPCConnection?
    private var helperProxy: HelperProtocol?
    private var isHelperInstalled = false

    private init() {
        checkHelperInstallation()
    }

    // MARK: - Helper Installation

    func checkHelperInstallation() {
        // Check if helper is already installed
        let status = SMAppService.statusForLegacyPlist(at: URL(fileURLWithPath: "/Library/LaunchDaemons/com.focusguard.helper.plist"))

        switch status {
        case .enabled:
            isHelperInstalled = true
            print("✅ Helper is installed and enabled")
        case .notRegistered, .notFound:
            isHelperInstalled = false
            print("⚠️ Helper is not installed")
        case .requiresApproval:
            isHelperInstalled = false
            print("⚠️ Helper requires approval")
        @unknown default:
            isHelperInstalled = false
        }
    }

    func installHelper(completion: @escaping (Bool, String?) -> Void) {
        // For SMJobBless to work, the app needs to be properly code-signed
        // and the helper needs matching code signing requirements

        var authRef: AuthorizationRef?
        var status = AuthorizationCreate(nil, nil, [], &authRef)

        guard status == errAuthorizationSuccess, let auth = authRef else {
            completion(false, "Failed to create authorization")
            return
        }

        defer { AuthorizationFree(auth, []) }

        // Request admin privileges
        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)

        status = AuthorizationCopyRights(auth, &rights, nil, [.interactionAllowed, .extendRights, .preAuthorize], nil)

        guard status == errAuthorizationSuccess else {
            completion(false, "Authorization denied")
            return
        }

        // Bless the helper
        var error: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, HelperConstants.helperBundleID as CFString, auth, &error)

        if success {
            isHelperInstalled = true
            print("✅ Helper installed successfully")
            completion(true, nil)
        } else {
            let errorDesc = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            print("❌ Failed to install helper: \(errorDesc)")
            completion(false, errorDesc)
        }
    }

    // MARK: - XPC Connection

    private func getHelperProxy() -> HelperProtocol? {
        if connection == nil {
            connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
            connection?.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)

            connection?.invalidationHandler = { [weak self] in
                self?.connection = nil
                self?.helperProxy = nil
            }

            connection?.interruptionHandler = { [weak self] in
                self?.helperProxy = nil
            }

            connection?.resume()
        }

        if helperProxy == nil {
            helperProxy = connection?.remoteObjectProxyWithErrorHandler { error in
                print("❌ XPC error: \(error)")
            } as? HelperProtocol
        }

        return helperProxy
    }

    // MARK: - Public API

    var isInstalled: Bool {
        return isHelperInstalled
    }

    func blockURLs(_ urls: [String], completion: @escaping (Bool, String?) -> Void) {
        guard let proxy = getHelperProxy() else {
            completion(false, "Could not connect to helper")
            return
        }

        proxy.blockURLs(urls) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func unblockURLs(_ urls: [String], completion: @escaping (Bool, String?) -> Void) {
        guard let proxy = getHelperProxy() else {
            completion(false, "Could not connect to helper")
            return
        }

        proxy.unblockURLs(urls) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    func removeAllBlocks(completion: @escaping (Bool, String?) -> Void) {
        guard let proxy = getHelperProxy() else {
            completion(false, "Could not connect to helper")
            return
        }

        proxy.removeAllBlocks { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
