<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# Views/

## Purpose
All SwiftUI views for the Close app — main list, contact detail, onboarding flow, settings, helper sheets, and UIKit bridges.

## Key Files

| File | Description |
|------|-------------|
| `ContactsListView.swift` | Main screen — `@Query` contact list re-sorted by `nextReminderDate` with search, swipe actions (done/call/message), empty state, contact picker sheet, onboarding trigger. `ContactRowView` is a top-level struct defined in this file — shows contact image, status text, call/message buttons, and a birthday cake icon indicator (fires on both "birthday" and "anniversary" custom dates matching today's month/day). |
| `ContactDetailView.swift` | Detail screen — header with image, quick actions (done/call/message), contact info, status section, important dates (add/delete custom dates), frequency picker with custom slider, notes editor, delete button. Uses `DatePickerSheet` for mark-as-contacted and `AddCustomDateSheet` for new dates. |
| `OnboardingView.swift` | Three-page `TabView` onboarding — welcome, notification permission request, ready page. Uses `@AppStorage("hasCompletedOnboarding")` and `interactiveDismissDisabled()`. |
| `SettingsView.swift` | Settings sheet — app info, notification/contacts permission status, help section with onboarding replay. |
| `ContactPickerView.swift` | `UIViewControllerRepresentable` wrapping `CNContactPickerViewController` — multi-select contact import. |
| `ContactCardView.swift` | `UIViewControllerRepresentable` wrapping `CNContactViewController` — read-only native contact card with done button. |
| `ContactImageView.swift` | Async contact photo loader — fetches `CNContact` image data on background thread, falls back to `person.circle.fill` SF Symbol. |
| `DatePickerSheet.swift` | Modal date picker for marking a contact as contacted on a specific date (past dates only). |
| `AddCustomDateSheet.swift` | Modal form for adding a manual custom date — label, date picker, recurring toggle. |

## For AI Agents

### Working In This Directory
- Views access `NotificationManager` via `@Environment(NotificationManager.self)` — never instantiate directly
- Views access `ModelContext` via `@Environment(\.modelContext)` — use for inserts, deletes, and saves
- `ContactScheduler()` is created locally in views that need scheduling — it defaults to `NotificationManager.shared`
- Phone/message/settings actions use `PhoneActions` enum from `Extensions/` — do not use `UIApplication.shared.open` directly
- Contact status display (color, text) should use `contact.status.color` and `contact.statusText` — do not recompute
- `ContactRowView` is defined inside `ContactsListView.swift`, not as a separate file
- Custom date deletion in `ContactDetailView` only allows deleting `.manual` source dates — `.contacts` sourced dates are protected
- All sheets use `NavigationStack` with `cancellationAction`/`confirmationAction` toolbar items
- Views use named colors from `Assets.xcassets`: `StatusRed`, `StatusOrange`, `StatusGreen`, `SoftBlue`, `SoftPurple`, `BackgroundPrimary`
