# iPhone / Waveshare fork test build

This build belongs to `asukachiharu/moto-gps-waveshare`, based on Maler X's
upstream project. It is separate from the previous MotoNav firmware/protocol.

当前交付：iOS 0.4.1（10）/ ESP 0.2.1。iPhone 编译、49 项 App 单元测试、
8 项离线界面测试及共享核心检查通过。测试记录：
https://github.com/asukachiharu/moto-gps-waveshare/actions/runs/42619576773

## 安装与设置

1. 用之前的签名工具安装 unsigned IPA，保留 Bundle ID `ink.yhm.MotoNav`。
2. 在地图首页点右侧设置入口，选择“高德 iOS SDK”。粘贴绑定上述
   Bundle ID 的 iOS Key，阅读隐私说明后保存。Key 留在手机钥匙串；
   无需重新编译。已经初始化 SDK 后更换 Key，需彻底关闭再打开 App。
3. 允许定位和蓝牙。开始导航后需要锁屏导航时，允许系统的后台定位。
   拒绝音乐权限不影响导航。先搜索地点，查看并选择路线，再开始导航。
4. ESP 必须使用此 fork 的配套 Waveshare 1.75C 固件。可先导航，再给
   圆屏通电；App 启动时会尝试连接。本文档不会自动执行烧录。
5. 自建服务仍可用：在没有进行导航时，将来源改为“自建网关”，填写
   自己的 HTTPS 网关地址。导航期间不能切换，失败不会静默改换来源。

## 本版行为与验证范围

- 同一张真实 MapKit 地图用于首页、路线选择和导航。搜索、设置、设备
  与下载放在原生可调整面板中；首页折叠时隐藏四个快捷入口。
- 定位/更多使用系统工具栏；上方导航指引采用不透明内容卡。日间、
  夜间、系统外观可选；iPhone Duo 使用系统原生面板布局。
- SDK 提供真实 POI、驾车备选路线和行政边界；手机真实 Core Location
  定位驱动上游共享 NavCore 并同步 BLE。它不是高德 DriveManager 的
  内部导航/语音引擎，不宣称摩托车限行或红绿灯能力。
- SDK 模式圆屏底图由手机直接读取公开 Protomaps PMTiles，无需网关。
  搜索城市/区县后可下载道路和建筑、暂停/继续、删除；仍保留上游
  40,000 瓦片和 512MB 离线限额，过大城市须按区县下载。本版未提供
  城市包的一键版本更新，不承诺整个城市一定能在限额内下载完成。
- 模拟器不包含设备版高德 SDK，不用演示数据代替真实 SDK 请求。
  自动界面测试、编译与打包成功不能证明户外定位、后台导航及真实
  蓝牙重连问题已经解决，仍需用配套手机和圆屏测试。

固件包包含烧录地址、SHA256 和实际解析的组件依赖记录。原作者署名、
非商业许可证及地图归属保留在 App 与固件分发包中。
