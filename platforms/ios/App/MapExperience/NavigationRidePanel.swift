import SwiftUI

struct NavigationRidePanel: View {
    @ObservedObject var model: AppModel
    let expanded: Bool
    let end: () -> Void
    let device: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.navigation.hasUsableFix ? model.remainingDurationText + " · " + model.remainingDistanceText : model.phaseTitle)
                            .font(.headline).monospacedDigit()
                        if model.navigation.hasUsableFix {
                            Text("预计 " + Date.now.addingTimeInterval(Double(model.navigation.remainingDurationS)).formatted(date: .omitted, time: .shortened) + " 到达")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button("结束导航", systemImage: "xmark.circle.fill", action: end)
                        .labelStyle(.iconOnly).font(.title2).accessibilityIdentifier("end-navigation")
                }
                if expanded {
                    Text(model.activeDestinationName).font(.title3.bold())
                    HStack {
                        Label(model.navigation.hasUsableFix && model.latestFix?.speedMps != nil ? "\(Int((max(0, model.latestFix?.speedMps ?? 0) * 3.6).rounded())) km/h" : "速度暂不可用", systemImage: "speedometer")
                        Spacer()
                        Button(model.deviceReady ? "圆屏已连接" : "连接圆屏", systemImage: "display", action: device)
                    }.font(.subheadline)
                    if let failure = model.navigationFailure { Text(failure).foregroundStyle(.secondary) }
                }
            }.padding(20)
        }.accessibilityIdentifier("active-navigation-panel")
    }
}
