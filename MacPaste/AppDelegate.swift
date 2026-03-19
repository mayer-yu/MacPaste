import SwiftUI
import AppKit

extension Notification.Name {
    static let macPastePerformPaste = Notification.Name("macPaste.performPaste")
}

/// 应用委托：管理菜单栏图标、Popover 与热键联动
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var previouslyActiveApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = AppIconFactory.makeAppIcon(size: 512)

        // 启动粘贴板监听
        PasteboardMonitor.shared.start()

        // 配置 Popover
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PasteHistoryView())
        popover.contentSize = NSSize(width: 360, height: 500)

        // 菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "list.clipboard.fill", accessibilityDescription: "MacPaste")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        // 热键触发时显示 Popover
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            self?.showPopover()
        }
        HotKeyManager.shared.register()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePerformPasteNotification),
            name: .macPastePerformPaste,
            object: nil
        )
    }

    @objc func togglePopover(_ sender: Any? = nil) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            previouslyActiveApp = app
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        PasteboardMonitor.shared.stop()
        HotKeyManager.shared.unregister()
    }

    @objc private func handlePerformPasteNotification() {
        guard HotKeyManager.shared.hasAccessibilityPermission else {
            HotKeyManager.shared.showPermissionGuide = true
            showPopover()
            return
        }

        closePopover()
        let targetApp = previouslyActiveApp
        targetApp?.activate(options: [.activateIgnoringOtherApps])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.simulateCommandV()
        }
    }

    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
