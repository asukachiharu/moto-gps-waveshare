import SwiftUI

struct MapDevicePanel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Form {
            Section {
                Label(status, systemImage: "display").font(.headline)
                LabeledContent("协议", value: model.device.negotiatedProtocol)
                Button(actionTitle, action: model.toggleDeviceConnection).accessibilityIdentifier("device-connection-action")
            } footer: {
                Text("可以先开始导航，再给圆屏通电。连接及握手完成后自动同步当前导航。")
            }
            if case let .failed(message) = model.device.connection { Section { Text(message) } }
            Section("定位") { Text(model.searchScopeText) }
        }.navigationTitle("我的圆屏").navigationBarTitleDisplayMode(.inline).accessibilityIdentifier("device-details-sheet")
    }
    private var status: String {
        switch model.device.connection {
        case .idle: "未连接"
        case .bluetoothUnavailable: "蓝牙不可用"
        case .scanning: "正在寻找圆屏"
        case .connecting: "正在连接"
        case .connected: model.deviceReady ? "已连接" : "正在握手"
        case .failed: "连接未成功"
        }
    }
    private var actionTitle: String {
        switch model.device.connection {
        case .connected: "断开连接"
        case .scanning, .connecting: "取消连接"
        default: "重新连接"
        }
    }
}
