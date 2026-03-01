<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# Close

## Purpose
An iOS app that helps users stay in touch with important contacts by tracking contact frequency and sending reminders. Built with SwiftUI and SwiftData, targeting iOS 17+. Users import contacts from their device address book, set a desired contact frequency (daily, weekly, monthly, etc.), and receive local notifications when it's time to reach out. Supports birthday/anniversary tracking via imported and manual custom dates.

## Key Files

| File | Description |
|------|-------------|
| `LICENSE` | Apache License 2.0 |
| `README.md` | Project overview with screenshots |
| `.gitignore` | Git ignore rules for Xcode/Swift projects |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `close/` | Main application source code — models, views, managers, extensions, and assets |
| `close.xcodeproj/` | Xcode project configuration (build settings, schemes, workspace) |
| `closeTests/` | Unit test target — model, scheduler, custom date, and edge case tests |
| `closeUITests/` | UI test target |
| `screenshots/` | App screenshots for the README (light and dark mode) |

## For AI Agents

### Working In This Directory
- This is a native iOS project — open `close.xcodeproj` in Xcode to build and run
- Swift source files live under `close/`, not at the root
- The app uses **SwiftData** for persistence (not Core Data) — the `@Model` macro and `ModelContainer`/`ModelContext` APIs
- The app uses the **Observation** framework (`@Observable`) rather than `ObservableObject`/`@Published`
- Custom colors are defined in `Assets.xcassets` — reference them by name string (e.g., `Color("StatusGreen")`, `Color("SoftBlue")`, `Color("BackgroundPrimary")`)
- The app requires iOS Contacts and Notification permissions at runtime
- `NotificationManager` is a singleton (`.shared`) injected via `.environment()` from the app root — views use `@Environment(NotificationManager.self)`
- Phone/message/settings actions are centralized in `PhoneActions` enum — do not duplicate URL-opening logic
- `AppDelegate` handles notification action responses (call, message, mark done) using `UNUserNotificationCenterDelegate`

### Build & Run
- Build: `xcodebuild -project close.xcodeproj -scheme close -destination 'platform=iOS Simulator,name=iPhone 17'`
- Test: `xcodebuild test -project close.xcodeproj -scheme closeTests -destination 'platform=iOS Simulator,name=iPhone 17'`
- No external dependencies or package managers (no SPM, CocoaPods, or Carthage)
- Minimum deployment target: iOS 17.0

### Architecture Overview
- **Pattern**: Standard SwiftUI MVVM-like structure with `Views/`, `Models/`, `Managers/`, `Extensions/`
- **Data flow**: `SwiftData @Model` → `@Query` in views → `ModelContext` for mutations
- **Notifications**: `ContactScheduler` orchestrates between `Contact` model and `NotificationManager` (injectable via init for testability)
- **Contact import**: `CNContactPickerViewController` wrapped via `UIViewControllerRepresentable` in `ContactPickerView`; import logic lives in `ContactsManager.importFromDeviceContacts()` which also imports birthdays and dates from the device contact
- **Custom dates**: `CustomDate` model with `@Relationship(deleteRule: .cascade)` back to `Contact`; supports both device-synced (`.contacts`) and manually-added (`.manual`) dates via `CustomDateSource` enum
- **Date sync**: `ContactsManager.refreshImportedDates()` syncs custom dates from iOS Contacts on app launch — adds new, updates changed, removes deleted
- **Status**: `Contact.Status` enum (`.overdue`, `.dueSoon`, `.onTrack`) with `Color` and `statusText` computed properties on the model — views should not duplicate this logic
- **Constants**: Magic values are extracted — `Contact.dueSoonThresholdDays`, `NotificationManager.defaultNotificationHour`, `ContactFrequency.customDaysRange`
- **CustomDate source**: Use `CustomDateSource` enum (`.contacts`, `.manual`) via `sourceType` computed property; raw `source` string is for SwiftData storage only

### Testing Requirements
- Unit tests use Swift Testing framework (`import Testing`, `@Test`, `#expect`) — not XCTest
- `makeTestContainer()` and `makeContact()` helpers in `closeTests.swift` for creating in-memory SwiftData test fixtures
- `MockNotificationManager` subclass in `ContactSchedulerTests.swift` for testing scheduler without hitting `UNUserNotificationCenter`
- Test coverage: `ContactFrequency` enum, `Contact` model properties/computed values, `CustomDate` model, `ContactScheduler` operations, edge cases (year boundary, threshold, nil dates)
- Run via Xcode Test navigator or `xcodebuild test`

## Dependencies

### External
- **SwiftUI** — UI framework
- **SwiftData** — Persistence (iOS 17+)
- **Contacts / ContactsUI** — Device address book access
- **UserNotifications** — Local notification scheduling

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
