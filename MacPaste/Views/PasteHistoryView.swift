import SwiftUI
import AppKit

/// 粘贴历史主视图
struct PasteHistoryView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @ObservedObject var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var searchText = ""
    @State private var showClearConfirm = false
    @State private var selectedItemID: UUID?

    private var filteredItems: [HistoryItem] {
        if searchText.isEmpty {
            return historyStore.items
        }
        return historyStore.items.filter { item in
            item.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if hotKeyManager.showPermissionGuide {
                PermissionGuideView()
            } else {
                header
                if historyStore.items.isEmpty {
                    emptyState
                } else {
                    searchField
                    historyList
                }
            }
        }
        .confirmationDialog("清空历史", isPresented: $showClearConfirm) {
            Button("清空", role: .destructive) {
                historyStore.clearAll()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清空所有粘贴历史吗？")
        }
        .onAppear {
            launchAtLoginManager.refreshStatus()
            selectFirstItemIfNeeded()
        }
        .onChange(of: filteredItems.map(\.id)) { _ in
            adjustSelectionForCurrentData()
        }
        .background(
            KeyAwareView { event in
                handleKeyEvent(event)
            }
            .frame(width: 0, height: 0)
        )
    }

    private var header: some View {
        HStack {
            Label("粘贴历史", systemImage: "doc.on.clipboard")
                .font(.headline)
            Spacer()
            Menu {
                if launchAtLoginManager.isSupported {
                    Toggle(
                        "开机自动启动",
                        isOn: Binding(
                            get: { launchAtLoginManager.isEnabled },
                            set: { launchAtLoginManager.setEnabled($0) }
                        )
                    )
                } else {
                    Text("当前系统版本不支持")
                }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)

            if !historyStore.items.isEmpty {
                Button {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .help("清空历史")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("暂无记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("复制文本后会出现在这里")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(width: 320, height: 240)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索历史...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        HistoryRowView(
                            item: item,
                            isSelected: selectedItemID == item.id
                        ) {
                            selectedItemID = item.id
                            copyAndPaste(item)
                        }
                        .id(item.id)
                        .contextMenu {
                            Button("复制", systemImage: "doc.on.doc") {
                                copyToPasteboard(item)
                            }
                            Button("删除", systemImage: "trash", role: .destructive) {
                                historyStore.remove(item)
                            }
                        }
                }
            }
                .onAppear {
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
                .onChange(of: selectedItemID) { _ in
                    scrollSelectionIntoView(using: proxy, animated: true)
                }
                .onChange(of: filteredItems.map(\.id)) { _ in
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSPopover.didShowNotification)) { _ in
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) { _ in
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)) { _ in
                    scrollSelectionIntoView(using: proxy, animated: false)
                }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            }
            .onChange(of: selectedItemID) { _ in
                scrollSelectionIntoView(using: proxy, animated: true)
            }
        }
        .frame(width: 360, height: 420)
    }

    private func copyAndPaste(_ item: HistoryItem) {
        copyToPasteboard(item)
        NotificationCenter.default.post(name: .macPastePerformPaste, object: nil)
    }

    private func copyToPasteboard(_ item: HistoryItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard !filteredItems.isEmpty else { return false }
        guard event.type == .keyDown else { return false }

        switch event.keyCode {
        case 125: // down
            moveSelection(step: 1)
            return true
        case 126: // up
            moveSelection(step: -1)
            return true
        case 36, 76: // return / enter
            if let item = selectedItem {
                copyAndPaste(item)
                return true
            }
            return false
        case 53: // esc
            NSApp.keyWindow?.performClose(nil)
            return true
        default:
            return false
        }
    }

    private var selectedItem: HistoryItem? {
        guard let selectedItemID else { return filteredItems.first }
        return filteredItems.first(where: { $0.id == selectedItemID }) ?? filteredItems.first
    }

    private func moveSelection(step: Int) {
        guard !filteredItems.isEmpty else { return }

        if selectedItemID == nil {
            selectedItemID = filteredItems.first?.id
            return
        }

        guard let currentID = selectedItemID,
              let currentIndex = filteredItems.firstIndex(where: { $0.id == currentID }) else {
            selectedItemID = filteredItems.first?.id
            return
        }

        let newIndex = min(max(currentIndex + step, 0), filteredItems.count - 1)
        selectedItemID = filteredItems[newIndex].id
    }

    private func selectFirstItemIfNeeded() {
        if selectedItemID == nil {
            selectedItemID = filteredItems.first?.id
        }
    }

    private func adjustSelectionForCurrentData() {
        guard !filteredItems.isEmpty else {
            selectedItemID = nil
            return
        }
        if let selectedItemID,
           filteredItems.contains(where: { $0.id == selectedItemID }) {
            return
        }
        self.selectedItemID = filteredItems.first?.id
    }

    private func scrollSelectionIntoView(using proxy: ScrollViewProxy, animated: Bool) {
        guard let selectedItemID else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.12)) {
                proxy.scrollTo(selectedItemID, anchor: .center)
            }
        } else {
            proxy.scrollTo(selectedItemID, anchor: .center)
        }
    }
}

struct HistoryRowView: View {
    let item: HistoryItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.preview)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    Text(item.relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

private struct KeyAwareView: NSViewRepresentable {
    let onEvent: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.installMonitor(onEvent: onEvent)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var localMonitor: Any?

        func installMonitor(onEvent: @escaping (NSEvent) -> Bool) {
            if localMonitor != nil { return }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if onEvent(event) {
                    return nil
                }
                return event
            }
        }

        deinit {
            if let localMonitor {
                NSEvent.removeMonitor(localMonitor)
            }
        }
    }
}

#Preview {
    PasteHistoryView()
}
