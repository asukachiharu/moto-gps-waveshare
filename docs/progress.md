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

Migrated the old List/push-navigation UI scripts to offline map-panel tests. Live
city search and demo UI entry scripts no longer describe this UI. SDK and real
navigation acceptance are not claimed by these offline tests. Device packaging
runs independently of UI tests so its failure/success is visible separately.
ESP-IDF 5.5.5 firmware build succeeded locally (not flashed); dependency resolver
updated the local lock, which is excluded from UI commits pending pin review.

Cloud run 42485820296 built the unsigned arm64 UI-preview IPA 0.4.0 (7) and
passed app unit tests plus all migrated offline UI tests on iPhone Duo. Source
checks 42485820264 passed. Local IPA structure verification passed. These checks
do not establish real-device navigation or BLE/background reliability.

The next revision adds explicit SDK/gateway selection (SDK default), local
Keychain entry and consent before SDK initialization. Official SDK POI, driving
route alternatives and administrative boundaries are adapted into the original
shared NavCore. This uses real Core Location fixes and shared-core guidance,
not AMapNaviDriveManager callbacks or its internal voice engine. Motorcycle
restriction and traffic-light support are not enabled. No API Key is bundled.
The persistent phone map is MapKit; Protomaps PMTiles/MVT is read directly on
the phone for the existing round-screen BLE scene, with bounded parsing and
GCJ-02 geometry. SDK mode requires no gateway. Gateway mode is retained;
active rides cannot change providers. Native attribution remains visible.
City packs retain the upstream 40,000-tile/512MB limits and deletion/resume;
large regions may require district downloads. Automatic city-pack updates
and a larger storage quota are not claimed by this revision.

2026-11-08 Windows checks: Python discovery completed with zero tests (this
fork uses C++/Swift/Node test suites); Python packaging scripts compile. Swift
and Xcode are unavailable locally; device SDK link, direct-map Swift 6 tests
and new mapper tests are submitted to cloud CI before acceptance. Firmware
source/protocol remains unchanged and the local resolver lock is not committed.

Cloud 42489142475: Swift core and DirectMapCore tests passed on Swift 6.
Device and simulator app builds caught a closure type-inference failure and
a concrete gateway type remaining in the explicit demo adapter. Both were
corrected before resubmission. No passing IPA is claimed for this failed run.
