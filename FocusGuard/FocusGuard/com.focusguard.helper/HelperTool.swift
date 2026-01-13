//
//  HelperTool.swift
//  FocusGuard Helper
//
//  Privileged helper that modifies /etc/hosts without password prompts
//

import Foundation

class HelperTool: NSObject, HelperProtocol, NSXPCListenerDelegate {

    private let listener: NSXPCListener
    private let version = "1.0.0"

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }

    func run() {
        self.listener.resume()
        RunLoop.current.run()
    }

    // MARK: - NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Verify the calling app is FocusGuard
        // In production, you'd verify the code signature here

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = self

        newConnection.invalidationHandler = {
            // Connection was invalidated
        }

        newConnection.interruptionHandler = {
            // Connection was interrupted
        }

        newConnection.resume()
        return true
    }

    // MARK: - HelperProtocol

    func blockURLs(_ urls: [String], withReply reply: @escaping (Bool, String?) -> Void) {
        do {
            var content = try String(contentsOfFile: HelperConstants.hostsFilePath, encoding: .utf8)

            // Build new entries
            var newEntries: [String] = []
            for url in urls {
                let entry = "127.0.0.1 \(url) \(HelperConstants.focusGuardMarker)"
                if !content.contains(entry) {
                    newEntries.append(entry)
                }
            }

            if !newEntries.isEmpty {
                content += "\n" + newEntries.joined(separator: "\n")
                try content.write(toFile: HelperConstants.hostsFilePath, atomically: true, encoding: .utf8)
                flushDNS()
            }

            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }

    func unblockURLs(_ urls: [String], withReply reply: @escaping (Bool, String?) -> Void) {
        do {
            let content = try String(contentsOfFile: HelperConstants.hostsFilePath, encoding: .utf8)
            var lines = content.components(separatedBy: .newlines)

            // Remove lines containing FocusGuard marker and matching URLs
            lines = lines.filter { line in
                if line.contains(HelperConstants.focusGuardMarker) {
                    for url in urls {
                        if line.contains(url) {
                            return false
                        }
                    }
                }
                return true
            }

            let newContent = lines.joined(separator: "\n")
            try newContent.write(toFile: HelperConstants.hostsFilePath, atomically: true, encoding: .utf8)
            flushDNS()

            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }

    func removeAllBlocks(withReply reply: @escaping (Bool, String?) -> Void) {
        do {
            let content = try String(contentsOfFile: HelperConstants.hostsFilePath, encoding: .utf8)
            var lines = content.components(separatedBy: .newlines)

            // Remove all FocusGuard lines
            lines = lines.filter { !$0.contains(HelperConstants.focusGuardMarker) }

            let newContent = lines.joined(separator: "\n")
            try newContent.write(toFile: HelperConstants.hostsFilePath, atomically: true, encoding: .utf8)
            flushDNS()

            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }

    func getVersion(withReply reply: @escaping (String) -> Void) {
        reply(version)
    }

    // MARK: - Private

    private func flushDNS() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        process.arguments = ["-flushcache"]
        try? process.run()
        process.waitUntilExit()

        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["-HUP", "mDNSResponder"]
        try? killall.run()
        killall.waitUntilExit()
    }
}
