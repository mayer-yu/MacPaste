import SwiftUI

@main
struct MacPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 菜单栏应用无需主窗口，保留 Settings 以满足 SwiftUI 对 Scene 的要求
        Settings {
            VStack(spacing: 16) {
                Text("MacPaste")
                    .font(.title2)
                Text("Shift+⌘+V 唤出粘贴历史")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 200, height: 80)
        }
    }
}
