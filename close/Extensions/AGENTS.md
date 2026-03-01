<!-- Generated: 2026-02-28 | Updated: 2026-03-01 -->

# Extensions/

## Purpose
Utility extensions and centralized helpers.

## Key Files

| File | Description |
|------|-------------|
| `PhoneActions.swift` | Static enum with `call(_:)`, `message(_:)`, and `openSettings()` methods. Sanitizes phone numbers (digits only) and opens `tel://`, `sms://`, or Settings URLs via `UIApplication.shared.open`. |

## For AI Agents

### Working In This Directory
- All phone/message/settings URL-opening logic is centralized here — do not duplicate `UIApplication.shared.open` calls elsewhere
- `PhoneActions.call` and `PhoneActions.message` sanitize the phone number to digits only before building the URL
- Used by `ContactsListView`, `ContactDetailView`, `SettingsView`, and `AppDelegate`
