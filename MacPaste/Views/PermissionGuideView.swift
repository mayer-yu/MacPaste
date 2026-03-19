import SwiftUI

/// 辅助功能权限引导视图
struct PermissionGuideView: View {
    @ObservedObject var hotKeyManager = HotKeyManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("需要辅助功能权限")
                .font(.headline)

            Text("为使用 Shift+⌘+V 唤出粘贴历史，请授予 MacPaste 辅助功能权限。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                hotKeyManager.requestAccessibilityPermission()
                hotKeyManager.openAccessibilitySettings()
            } label: {
                Label("去授权", systemImage: "hand.raised")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("我已授权，重新检测") {
                hotKeyManager.checkPermission()
                if hotKeyManager.hasAccessibilityPermission {
                    hotKeyManager.showPermissionGuide = false
                    hotKeyManager.register()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(width: 280)
    }
}

#Preview {
    PermissionGuideView()
}
