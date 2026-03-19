import SwiftUI
import AppKit

/// 粘贴历史主视图
struct PasteHistoryView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @ObservedObject var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var searchText = ""
    @State private var showClearConfirm = false

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
        }
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredItems) { item in
                    HistoryRowView(item: item) {
                        copyAndPaste(item)
                    }
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
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
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
}

struct HistoryRowView: View {
    let item: HistoryItem
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
            .background(.regularMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

#Preview {
    PasteHistoryView()
}
