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

2026-11-09 resume: run 42490382267 produced the verified unsigned arm64 IPA
0.4.1 (9); Source checks 42490382107 passed all four jobs. App unit tests
passed 49/49 and offline UI tests passed 7/8, including SDK Key rejection,
sheet collapse, theme changes and large text. The first UI launch failed
before interaction with "does not have a process ID"; subsequent logs show
media/location permission alerts from the earlier app-hosted unit-test launch.
The test scheme now passes the existing offline flag to that host too, and
CI waits for simulator boot. No retry hides failures. Release app code and
firmware are unchanged by this test-environment correction; rerun pending.

Local distribution checks: IPA Bundle ID ink.yhm.MotoNav, official SDK bundles,
unsigned/unencrypted device binary, no embedded signing assets and no supplied
private Key. SHA256 ca8052341b74c9605fbdc31ad1b97887f219f456048c445bf59bdec186d547b6.
ESP package 0.2.1 is compiled, not flashed, and includes its actual resolved
dependency lock and component licences. Generated local lock was restored to
the repository version. Real iPhone/ESP background and navigation remain untested.

Final map review found that changing heading follow during a ride required
another recenter action. The coordinator now applies a changed requested mode
immediately while preserving manual pans across ordinary GPS ticks. Route
selection explicitly labels driving routes; motorcycle restrictions remain
unsupported. Build number advances to 10 for these production UI corrections.
Run 42618875354's device job failed before compilation because the official
AMap download connection timed out. The previously verified build 9 remains
available; it is not represented as a new build 10 artifact.
