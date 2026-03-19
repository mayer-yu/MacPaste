import Foundation

/// 粘贴历史持久化存储
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    @Published private(set) var items: [HistoryItem] = []
    
    private let fileManager = FileManager.default
    private let maxItemCount = 200
    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("MacPaste", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("history.json")
    }

    private init() {
        load()
    }

    /// 添加新记录（自动去重相邻相同内容）
    func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 若与最新一条相同则跳过
        if items.first?.text == trimmed {
            return
        }

        let item = HistoryItem(text: trimmed)
        items.insert(item, at: 0)
        
        if items.count > maxItemCount {
            items = Array(items.prefix(maxItemCount))
        }
        
        save()
    }

    /// 删除指定项
    func remove(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    /// 清空历史
    func clearAll() {
        items = []
        save()
    }

    private func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([HistoryItem].self, from: data)
            items = decoded
        } catch {
            print("HistoryStore load error: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL)
        } catch {
            print("HistoryStore save error: \(error)")
        }
    }
}
