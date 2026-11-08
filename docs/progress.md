# Fork development progress

2026-11-08: Forked from mx3353672833-debug/moto-gps-waveshare, upstream 2ba1737.
Work branch: codex/ios-native-navigation. Original NOTICE, LICENSE and authorship remain.

The iOS UI now uses one persistent interactive map and a native resizable sheet.
Home shortcuts disappear at the compact detent; search, route choices, ride summary,
settings and device controls share the original root-owned navigation/BLE services.
Stopping a ride requires explicit confirmation; panel navigation does not end a ride.
Day/night/system appearance and heading follow are user settings. Normal UI has no demo entry.
SDK/gateway provider adaptation is in progress; this first UI commit retains the gateway.

Windows has no Swift/Xcode. Cloud Xcode 27.1 device build and simulator tests are pending.
The original protocol, navigation core and ESP firmware have not changed. No flashing,
certificate installation or runner registration has been performed. Real BLE/background
reliability still needs paired iPhone and round-screen testing.
