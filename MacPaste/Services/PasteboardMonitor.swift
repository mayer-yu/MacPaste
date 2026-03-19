import AppKit
import Combine

/// 监听系统粘贴板变化，仅保存文本
final class PasteboardMonitor: ObservableObject {
    static let shared = PasteboardMonitor()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let pollInterval: TimeInterval = 0.5

    private init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        timer?.tolerance = 0.2
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            HistoryStore.shared.add(text)
        }
    }
}
