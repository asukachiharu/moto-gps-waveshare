import SwiftUI

struct NavigationSettingsPanel: View {
    @ObservedObject var model: AppModel
    @AppStorage("MotoGPS.Appearance") private var appearance = "system"
    @AppStorage("MotoGPS.FollowHeading") private var followHeading = true
    var body: some View {
        Form {
            Section("导航服务") {
                NavigationLink("网关设置") { GatewaySettingsView(model: model) }
                    .accessibilityIdentifier("gateway-settings-link")
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
    }
}
