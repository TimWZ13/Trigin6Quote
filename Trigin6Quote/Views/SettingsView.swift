import SwiftUI
import AppKit
import ServiceManagement

/// 设置视图 — 外观、字号、分享等实际可配置项
/// ©️Trigin
struct SettingsView: View {
    @EnvironmentObject var store: QuoteStore
    @Environment(\.colorScheme) private var colorScheme

    // 外观模式：0=跟随系统 1=浅色 2=深色
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    // 字号：0=小 1=中 2=大
    @AppStorage("quoteFontSize") private var quoteFontSize: Int = 1
    // 分享时附带应用签名
    @AppStorage("shareWithSignature") private var shareWithSignature: Bool = true
    // 开机自启动 — 通过 SMAppService 注册（macOS 13+，沙盒/App Store 兼容）
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            aboutSettings
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 460, height: 420)
    }

    // MARK: - 通用设置

    private var generalSettings: some View {
        Form {
            Section("外观") {
                Picker("显示模式", selection: $appearanceMode) {
                    Text("跟随系统").tag(0)
                    Text("浅色模式").tag(1)
                    Text("深色模式").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: appearanceMode) { _, newValue in
                    // 通知 App 重新应用配色
                    NotificationCenter.default.post(name: .appearanceDidChange, object: nil)
                }

                Picker("语录字号", selection: $quoteFontSize) {
                    Text("小").tag(0)
                    Text("中").tag(1)
                    Text("大").tag(2)
                }
                .pickerStyle(.segmented)
                .onChange(of: quoteFontSize) { _, _ in
                    NotificationCenter.default.post(name: .fontSizeDidChange, object: nil)
                }
            }

            Section("分享") {
                Toggle("分享时附带应用签名", isOn: $shareWithSignature)
                    .onChange(of: shareWithSignature) { _, _ in
                        NotificationCenter.default.post(name: .sharePreferenceDidChange, object: nil)
                    }
            }

            Section("启动") {
                Toggle("开机自启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        guard AppInfo.isProperlyBundled else {
                            print("开机自启动仅在打包为 .app 后可用（当前为调试模式）")
                            return
                        }
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                            print("开机自启动设置失败: \(error.localizedDescription)")
                        }
                    }
                    .onAppear {
                        guard AppInfo.isProperlyBundled else { return }
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
            }

            Section("语录数据") {
                HStack {
                    Text("总语录数")
                    Spacer()
                    Text("\(store.totalQuoteCount) 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                HStack {
                    Text("每日展示")
                    Spacer()
                    Text("6 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                HStack {
                    Text("已收藏")
                    Spacer()
                    Text("\(store.favorites.count) 条")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .padding()
    }

    // MARK: - 关于

    private var aboutSettings: some View {
        VStack(spacing: 20) {
            Image(systemName: "6.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent)

            Text("Trigin6Quote")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text("每天六句精选语录，激励你不断前行")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("共 \(store.totalQuoteCount) 条精选语录")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Spacer()

            Text("\(AppInfo.copyright)  v\(AppInfo.version)")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let appearanceDidChange = Notification.Name("appearanceDidChange")
    static let fontSizeDidChange = Notification.Name("fontSizeDidChange")
    static let sharePreferenceDidChange = Notification.Name("sharePreferenceDidChange")
}
