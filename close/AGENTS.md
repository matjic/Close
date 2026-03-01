<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# close/ — Main Application Source

## Purpose
Contains all application source code for the Close iOS app: models, views, managers, extensions, and assets.

## Key Files

| File | Description |
|------|-------------|
| `closeApp.swift` | App entry point (`@main`); configures `ModelContainer` with `Contact` and `CustomDate` schemas, injects `NotificationManager` via environment, includes `AppDelegate` for handling notification actions (call, message, mark done) |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `Models/` | SwiftData `@Model` classes and supporting enums |
| `Views/` | All SwiftUI views — list, detail, onboarding, settings, sheets, and UIKit bridges |
| `Managers/` | Business logic — contact scheduling, notification management, contacts import |
| `Extensions/` | Utility extensions — phone/message/settings URL actions |
| `Assets.xcassets/` | Color assets (`StatusRed`, `StatusOrange`, `StatusGreen`, `SoftBlue`, `SoftPurple`, `BackgroundPrimary`) and app icon |

## For AI Agents

### Working In This Directory
- `closeApp.swift` is the sole `@main` entry point — do not create additional app structs
- `AppDelegate` in `closeApp.swift` handles `UNUserNotificationCenterDelegate` — notification action responses (call, message, done) route through here
- `ModelContainer` schema includes both `Contact.self` and `CustomDate.self` — add new `@Model` types to the schema array
- `NotificationManager.shared` is injected at the root `WindowGroup` level — all child views access it via `@Environment(NotificationManager.self)`
- The `appDelegate.modelContainer` is set in `.onAppear` so the delegate can query contacts for notification actions
