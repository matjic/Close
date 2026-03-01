<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# Models/

## Purpose
SwiftData `@Model` classes and supporting types that define the app's data layer.

## Key Files

| File | Description |
|------|-------------|
| `Contact.swift` | Main `@Model` — stores name, phone, email, frequency, last contacted date, notes, and device contact identifier. Computed properties: `nextReminderDate`, `daysUntilNextContact`, `isOverdue`, `isDueSoon`, `status`, `statusText`. Has `@Relationship(deleteRule: .cascade)` to `[CustomDate]`. |
| `ContactFrequency.swift` | `ContactFrequency` enum (daily/weekly/biweekly/monthly/quarterly/yearly/custom) — `String` raw value, `Codable`, `CaseIterable`. Provides `days: Int?` (nil for custom) and `customDaysRange` (1...365). |
| `CustomDate.swift` | `@Model` for birthdays, anniversaries, and other important dates. Linked to `Contact` via inverse relationship. `CustomDateSource` enum (`.contacts`/`.manual`) exposed via `sourceType` computed property; raw `source` string is for SwiftData storage. |

## For AI Agents

### Working In This Directory
- `Contact.frequencyType` is a `String` stored by SwiftData; use the `frequency` computed property (get/set) for type-safe access via `ContactFrequency`
- `Contact.customDaysInterval` is only meaningful when `frequency == .custom`
- Status logic lives on `Contact` — `status: Status`, `statusText: String`, `status.color: Color` — do not reimplement in views
- `Contact.dueSoonThresholdDays` (currently 3) is the boundary between `.dueSoon` and `.onTrack`
- `CustomDate.source` is a raw `String` for SwiftData; always use `sourceType` (a `CustomDateSource`) for reads/writes in app code
- `CustomDate.isRecurring` controls whether date notifications repeat annually
- When adding new stored properties to `@Model` classes, provide defaults for lightweight migration
