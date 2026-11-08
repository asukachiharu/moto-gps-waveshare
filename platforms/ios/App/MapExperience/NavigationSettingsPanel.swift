import SwiftUI

struct NavigationSettingsPanel: View {
    @ObservedObject var model: AppModel
    @AppStorage("MotoGPS.Appearance") private var appearance = "system"
    @AppStorage("MotoGPS.FollowHeading") private var followHeading = true
    @State private var source: NavigationSourceMode = .sdk
    @State private var key = ""
    @State private var consent = false
    @State private var message: String?
    var body: some View {
        Form {
            Section("导航服务") {
                Picker("导航来源", selection: $source) {
                    ForEach(NavigationSourceMode.allCases) { mode in Text(mode.title).tag(mode) }
                }.disabled(model.isNavigationActive || model.isUpdatingGateway).accessibilityIdentifier("navigation-source-picker")
                if source == .sdk {
                    SecureField(model.sdkHasKey ? "已保存 Key；输入可替换" : "粘贴高德 iOS Key", text: $key)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("amap-key-input")
                    Toggle("同意高德隐私政策", isOn: $consent).accessibilityIdentifier("amap-privacy-consent")
                    Link("阅读高德隐私政策", destination: URL(string: "https://lbs.amap.com/pages/privacy/")!)
                    Button("保存 Key 与隐私选择") {
                        do {
                            try model.saveSDKSettings(key: key, consent: consent)
                            key = ""; message = model.sdkRequiresRestart ? "Key 已保存，重新打开 App 后生效。" : "已保存。"
                        } catch { message = error.localizedDescription }
                    }.disabled(model.isNavigationActive).accessibilityIdentifier("amap-key-save")
                    if !MNSearchSDKBridge.available { Text("模拟器不包含高德设备 SDK。请在 iPhone 使用 SDK 模式。").font(.caption).foregroundStyle(.secondary) }
                    Text("iOS Key 需绑定 ink.yhm.MotoNav，仅保存在本机钥匙串。搜索和算路由高德 SDK 提供，行驶指引使用原项目共享导航核心。").font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink("网关设置") { GatewaySettingsView(model: model) }
                    .accessibilityIdentifier("gateway-settings-link")
                Text("导航途中不能切换来源；SDK 模式不会自动把位置或路线请求改发到网关。").font(.caption).foregroundStyle(.secondary)
                if let message { Text(message).foregroundStyle(.secondary).accessibilityIdentifier("navigation-settings-message") }
            }
            Section("外观") {
                Picker("显示模式", selection: $appearance) {
                    Text("自动").tag("system"); Text("白天").tag("light"); Text("夜间").tag("dark")
                }.pickerStyle(.segmented).accessibilityIdentifier("appearance-picker")
                Toggle("导航时朝向前方", isOn: $followHeading)
            }
            Section("关于") {
                Text("MOTO GPS · Waveshare Edition").font(.headline)
                Text("基于 Maler X 的原项目修改，遵循 PolyForm Noncommercial 1.0.0。")
                Link("原项目与作者", destination: URL(string: "https://github.com/mx3353672833-debug/moto-gps-waveshare")!)
                NavigationLink("隐私与数据") { DataUseView() }
            }
        }.navigationTitle("设置").navigationBarTitleDisplayMode(.inline)
            .onAppear { source = model.navigationSource; consent = model.sdkPrivacyAgreed }
            .onChange(of: model.navigationSource) { _, mode in source = mode }
            .onChange(of: source) { _, mode in
                Task {
                    do { try await model.chooseNavigationSource(mode); message = nil }
                    catch { source = model.navigationSource; message = error.localizedDescription }
                }
            }
    }
}
