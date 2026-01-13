//
//  FrictionDelayView.swift
//  FocusGuard
//
//  10-second countdown + type phrase to disable blocks
//

import SwiftUI

struct FrictionDelayView: View {
    let block: WebsiteBlock
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @State private var countdown: Int = 10
    @State private var countdownComplete = false
    @State private var typedPhrase = ""
    @State private var showError = false

    private let requiredPhrase = "I want to disable this block"

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Disabling Block")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("for \(block.url)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Divider()

            if !countdownComplete {
                // Countdown phase
                countdownView
            } else {
                // Type phrase phase
                typePhraseView
            }

            Divider()

            // Cancel button (always available)
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(width: 400)
        .onAppear {
            startCountdown()
        }
    }

    private var countdownView: some View {
        VStack(spacing: 16) {
            Text("Wait for countdown...")
                .font(.headline)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / 10.0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)

                Text("\(countdown)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }

            Text("You cannot skip this countdown")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var typePhraseView: some View {
        VStack(spacing: 16) {
            Text("Type this phrase to confirm:")
                .font(.headline)

            Text("\"\(requiredPhrase)\"")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

            TextField("Type here...", text: $typedPhrase)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            if showError {
                Text("Phrase doesn't match. Try again.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button("Disable Block") {
                verifyAndDisable()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(typedPhrase.isEmpty)
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                withAnimation {
                    countdownComplete = true
                }
            }
        }
    }

    private func verifyAndDisable() {
        if typedPhrase.lowercased().trimmingCharacters(in: .whitespaces) == requiredPhrase.lowercased() {
            onConfirm()
        } else {
            showError = true
            typedPhrase = ""

            // Hide error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
        }
    }
}

// MARK: - Friction Delay Window Controller

class FrictionDelayWindowController {
    static let shared = FrictionDelayWindowController()

    private var window: NSWindow?

    private init() {}

    func showFrictionDelay(for block: WebsiteBlock, onCancel: @escaping () -> Void, onConfirm: @escaping () -> Void) {
        // Close existing window if any
        window?.close()

        // Create the view
        let frictionView = FrictionDelayView(
            block: block,
            onCancel: { [weak self] in
                self?.window?.close()
                onCancel()
            },
            onConfirm: { [weak self] in
                self?.window?.close()
                onConfirm()
            }
        )

        // Create window
        let hostingController = NSHostingController(rootView: frictionView)

        window = NSWindow(contentViewController: hostingController)
        window?.title = "FocusGuard - Confirm Disable"
        window?.styleMask = [.titled, .closable]
        window?.level = .floating
        window?.center()

        // Prevent closing with Escape key
        window?.isReleasedWhenClosed = false

        // Show window
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
