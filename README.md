# FocusGuard

A productivity system for macOS that helps you block distracting websites and stay focused. Includes a menu bar app and a Brave/Chrome browser extension.

## Why FocusGuard?

Most website blockers make it too easy to disable them. FocusGuard adds **friction** — not impossible barriers, but enough resistance that you have to consciously acknowledge you're choosing distraction. The typing requirement forces a moment of self-reflection before you can proceed.

## Features

### macOS Menu Bar App
- **System-wide blocking** via `/etc/hosts` modification
- **Flexible durations**: 1 hour, 2 hours, or custom time
- **Scheduled blocks**: Automatically block sites during work hours (e.g., Twitter blocked 9am-5pm on weekdays)
- **Friction system**: To unblock early, you must wait through a countdown AND type a confirmation phrase
- **Shame stats**: Track bypasses, time wasted, and blocks activated
- **Morning prompts**: Daily notification to set your focus intentions

### Browser Extension (Brave/Chrome)
- **Pre-emptive intervention**: Catches you *before* you visit blocked sites
- **Daily time limits**: Like Apple Screen Time — set a max time per site (e.g., 15 min/day on Twitter)
- **Escalating bypass phrases**: The more you bypass, the harder the phrase:
  - Low: *"I am choosing to waste my time"*
  - Medium: *"I am actively choosing distraction over my goals"*
  - High: *"I am sabotaging my own productivity again"*
  - Critical: *"I refuse to respect my own boundaries"*
- **Periodic reminders**: Nudges you every 3 minutes while on a distracting site
- **Usage tracking**: See how much time you've spent on blocked sites

## Installation

### macOS App

1. Clone this repository
2. Open `FocusGuard/FocusGuard.xcodeproj` in Xcode
3. Update the Development Team in Signing & Capabilities
4. Build and run (⌘+R)
5. The app appears in your menu bar as a shield icon

### Browser Extension

1. Open Brave/Chrome and go to `brave://extensions` or `chrome://extensions`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `BraveExtension` folder from this repo
5. The FocusGuard icon appears in your browser toolbar

## How It Works

**Blocking**: The macOS app modifies `/etc/hosts` to redirect blocked domains to `127.0.0.1`. This works system-wide across all browsers and apps.

**Intervention**: The browser extension intercepts navigation to blocked sites and shows an intervention page before you can proceed.

**Time Limits**: The extension tracks active time on sites. When you hit your daily limit, you're shown the intervention page and must request more time (with the bypass phrase).

## Tech Stack

- **macOS App**: SwiftUI, Core Data, AppKit
- **Browser Extension**: JavaScript, Chrome Extension Manifest V3
- **Blocking**: `/etc/hosts` modification via AppleScript with admin privileges

## Screenshots

*Coming soon*

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT License — feel free to use, modify, and distribute.

---

Built with the help of [Claude Code](https://claude.ai/code)
