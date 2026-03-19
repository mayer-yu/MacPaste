# MacPaste

MacPaste is a lightweight **macOS menu bar clipboard manager** built with **SwiftUI**.
It focuses on a clean text-only workflow: capture copied text, open history with `Shift + Command + V`, and paste quickly back into the active app.

## Highlights

- Native macOS app (menu bar only, no Dock icon)
- Global hotkey: `Shift + Command + V`
- Clipboard history for **text only** (no images)
- Local persistence to disk (`Application Support/MacPaste/history.json`)
- Accessibility permission guidance for hotkey/paste automation
- Launch at login toggle (macOS 13+)
- Simple, polished SwiftUI interface

## Tech Stack

- Swift 5
- SwiftUI
- AppKit (status bar, popover, pasteboard)
- Carbon hotkey API (global shortcut)
- ServiceManagement (`SMAppService`) for launch-at-login

## Project Structure

- `MacPaste/MacPasteApp.swift` – App entry point
- `MacPaste/AppDelegate.swift` – status bar, popover, app lifecycle
- `MacPaste/Models/HistoryItem.swift` – clipboard item model
- `MacPaste/Services/HistoryStore.swift` – JSON persistence
- `MacPaste/Services/PasteboardMonitor.swift` – clipboard polling
- `MacPaste/Services/HotKeyManager.swift` – global hotkey registration
- `MacPaste/Services/LaunchAtLoginManager.swift` – launch-at-login manager
- `MacPaste/Views/PasteHistoryView.swift` – main history UI
- `MacPaste/Views/PermissionGuideView.swift` – accessibility permission guide

## Requirements

- macOS 13.0+
- Xcode 15+

## Build & Run

### Run from Xcode

1. Open `MacPaste.xcodeproj`
2. Select the `MacPaste` scheme
3. Press Run

> Note: If you stop/close Xcode during a debug run, the app stops (expected behavior).

### Build from Command Line

```bash
xcodebuild -project MacPaste.xcodeproj -scheme MacPaste -configuration Debug -sdk macosx build
```

### Create a Local Release Build

```bash
xcodebuild -project MacPaste.xcodeproj -scheme MacPaste -configuration Release -sdk macosx build
```

Then copy the generated `MacPaste.app` from DerivedData to `/Applications` and launch it directly.

## Permissions

MacPaste needs **Accessibility permission** to:

- listen to and trigger global paste workflow
- simulate `Command + V` after choosing a history item

If permission is missing, the app shows an in-app guide and can jump to the correct System Settings page.

## Data Storage

Clipboard history is stored locally on your machine:

- `~/Library/Application Support/MacPaste/history.json`

No cloud sync, no external data upload.

## Roadmap Ideas

- Pin frequently used snippets
- Better search and keyboard navigation
- Optional encrypted local storage
- Import/export history

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
