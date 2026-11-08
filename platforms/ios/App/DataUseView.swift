import SwiftUI

/// Available without a connection, so permission and storage information can
/// still be read when the gateway or the accessory is unavailable.
struct DataUseView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("位置与路线") {
                    Text("地点搜索和路线规划时，搜索内容、起终点及所需位置会发送给所选导航服务。SDK 模式直接请求高德；网关模式先请求你配置的服务器，再由服务器请求高德。圆屏底图由 Protomaps 提供，SDK 模式由手机直接下载地图区域。")
                    Text("导航期间，定位用于更新路线和圆屏指引；锁屏或切换应用后仍可继续。结束导航会停止导航定位。可在系统设置中调整权限。")
                }
                Section("蓝牙与音乐") {
                    Text("连接圆屏后，导航、速度及周边地图通过蓝牙同步。允许媒体资料库权限后，Apple Music 的曲名、歌手和播放状态也会同步到圆屏，圆屏可控制上一首、播放或暂停、下一首。")
                    Text("音乐信息不发送到 MOTO GPS 的导航服务器。拒绝音乐权限不影响地点搜索和导航。")
                }
                Section("存储与清理") {
                    Text("最近地点、已连接设备标识和下载地图保存在手机上。首页可清空最近搜索；地图与离线下载页面可删除下载包、清理临时缓存。删除 App 可移除它的本地数据；系统备份可能包含部分本地数据。")
                    Text("高德 iOS Key 保存在本机钥匙串，不写入安装包或普通设置。钥匙串中的 Key 可能在重新安装 App 后保留。")
                    Text("服务器访问日志可能保留 IP、请求时间、搜索词、位置参数及地图区域。记录范围、轮转和保留期限由部署方的实际配置及隐私政策说明；这不等于数据只在手机上保存。")
                }
                Section {
                    Link("高德隐私政策", destination: URL(string: "https://lbs.amap.com/home/privacy/")!)
                    Link("Apple 隐私政策", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                    Link("OpenStreetMap 数据与许可", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    Link("Protomaps 地图数据", destination: URL(string: "https://protomaps.com")!)
                } header: {
                    Text("第三方服务")
                } footer: {
                    Text("手机路线底图由 Apple 地图提供，圆屏周边道路与建筑使用 OpenStreetMap / Protomaps 数据。")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("隐私与数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { if let onClose { onClose() } else { dismiss() } }
                        .accessibilityIdentifier("privacy-data-done")
                }
            }
        }
    }
}
