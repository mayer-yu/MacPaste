import AppKit
import Carbon
import Carbon.HIToolbox
import ApplicationServices

private func hotKeyHandler(_: OpaquePointer?, _ event: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus {
    return HotKeyManager.shared.handleHotKey(event)
}

/// 全局热键管理，需辅助功能权限
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    @Published private(set) var hasAccessibilityPermission: Bool = false
    @Published var showPermissionGuide: Bool = false
    
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D435050), id: 1) // "MCPP"
    private var eventHandler: EventHandlerRef?
    
    /// 热键被触发时的回调（在主线程）
    var onHotKeyPressed: (() -> Void)?

    private init() {
        checkPermission()
    }

    deinit {
        unregister()
    }

    func checkPermission(prompt: Bool = false) {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
        } else {
            hasAccessibilityPermission = AXIsProcessTrusted()
        }
        showPermissionGuide = !hasAccessibilityPermission
    }

    func requestAccessibilityPermission() {
        checkPermission(prompt: true)
    }

    /// 打开系统辅助功能设置页
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple-systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// 注册 Shift+Command+V
    func register() {
        unregister()
        checkPermission()
        guard hasAccessibilityPermission else {
            showPermissionGuide = true
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status1 = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        guard status1 == noErr else {
            print("HotKeyManager: InstallEventHandler failed: \(status1)")
            return
        }

        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        let status2 = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status2 != noErr {
            print("HotKeyManager: RegisterEventHotKey failed: \(status2)")
        }
    }

    fileprivate func handleHotKey(_ event: EventRef?) -> OSStatus {
        var hotKeyIDReceived = EventHotKeyID()
        guard let event = event,
              GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyIDReceived) == noErr,
              hotKeyIDReceived.id == hotKeyID.id else {
            return OSStatus(eventNotHandledErr)
        }
        DispatchQueue.main.async { [weak self] in
            self?.onHotKeyPressed?()
        }
        return noErr
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}
