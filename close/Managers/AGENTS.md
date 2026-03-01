<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# Managers/

## Purpose
Business logic layer — contact scheduling, notification management, and device contacts import/sync.

## Key Files

| File | Description |
|------|-------------|
| `ContactScheduler.swift` | `@MainActor` coordinator between `Contact` model and `NotificationManager`. Methods: `updateSchedule`, `updateSchedules`, `updateCustomDateSchedules`, `cancelSchedule`, `refreshAllSchedules`, `markContactedAndReschedule`. Injectable `NotificationManager` via init (defaults to `.shared`) for testability. |
| `NotificationManager.swift` | `@Observable` singleton managing `UNUserNotificationCenter`. Handles authorization, notification category setup (call/message/done actions), scheduling contact reminders and custom date notifications (recurring and one-off), and cancellation. Key constants: `categoryIdentifier`, `callActionIdentifier`, `messageActionIdentifier`, `doneActionIdentifier`, `defaultNotificationHour` (9 AM). |
| `ContactsManager.swift` | `@Observable` class for iOS Contacts framework access. Handles permission requests, fetching device contacts (with birthday and dates), importing contacts into SwiftData (with birthday/date `CustomDate` creation), refreshing imported dates on launch (add/update/remove sync), and opening Settings. Also defines `DeviceContact` struct. |

## For AI Agents

### Working In This Directory
- `ContactScheduler` is the **only** place that coordinates model updates with notification scheduling — views should call scheduler methods, not `NotificationManager` directly for contact reminders
- `NotificationManager` is `@Observable` (not `ObservableObject`) — injected via `.environment()`, accessed via `@Environment(NotificationManager.self)`
- `NotificationManager.shared` is the singleton — `ContactScheduler` defaults to it; tests use `MockNotificationManager` subclass
- `ContactsManager.importFromDeviceContacts()` handles deduplication via `contactIdentifier` and creates `CustomDate` entries for birthdays and other dates found in the device contact
- `ContactsManager.refreshImportedDates()` runs on app launch — it syncs imported dates (add new, update changed, remove deleted) by comparing against the current iOS Contacts state
- `ContactsManager` fetches contacts on a detached task (`Task.detached`) to avoid blocking the main actor
- Notification identifiers: contact reminders use `contact.id.uuidString`; custom date notifications use `"\(contact.id.uuidString)-\(customDate.id.uuidString)"`
- Custom date notifications: recurring dates use month/day components (annual repeat); one-off dates use full year/month/day and are skipped if in the past
