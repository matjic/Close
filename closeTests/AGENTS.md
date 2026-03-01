<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# closeTests/

## Purpose
Unit tests for models, scheduler, and edge cases using the Swift Testing framework.

## Key Files

| File | Description |
|------|-------------|
| `closeTests.swift` | Test helpers (`makeTestContainer`, `makeContact`) and test suites: `ContactFrequencyTests` (all enum cases, display names), `ContactTests` (init, defaults, frequency get/set, next reminder date, days until contact, overdue/due soon/on track status, mark as contacted), `CustomDateTests` (init, source types), `ContactEdgeCaseTests` (nil last contacted, year boundary, status text, threshold), `CustomDateEdgeCaseTests` (source type round-trips, setter). |
| `ContactSchedulerTests.swift` | `MockNotificationManager` subclass (tracks scheduled/cancelled contacts and custom dates). `ContactSchedulerTests` suite: mark contacted and reschedule, update schedule, update multiple schedules, cancel schedule (contact + custom dates), refresh all, update custom date schedules. |

## For AI Agents

### Working In This Directory
- Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`) — not XCTest
- `makeTestContainer()` creates an in-memory `ModelContainer` for `Contact.self` and `CustomDate.self`
- `makeContact(in:)` is a `@MainActor` helper that inserts a contact into the container's main context
- `MockNotificationManager` overrides all scheduling/cancellation methods to record calls in arrays — use it for any new scheduler tests
- All `@Test` functions that touch SwiftData must be `@MainActor` and `throws`
- Test naming convention: descriptive camelCase (e.g., `nextReminderDateCustomFrequency`, `cancelScheduleCancelsContactAndCustomDates`)
- Run: `xcodebuild test -project close.xcodeproj -scheme closeTests -destination 'platform=iOS Simulator,name=iPhone 17'`
