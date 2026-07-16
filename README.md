# Follow-up Tracker

A Flutter app for tracking daily customer follow-up calls, pending amounts,
and reschedules — built for someone making many calls a day and needing a
fast way to log outcomes and know who to call next.

## Stack
- Flutter (Material 3)
- `provider` for state management (`TrackerProvider`)
- `sqflite` for local, offline-first storage
- `intl` for date/currency formatting
- `url_launcher` to place calls directly from a follow-up card

## Structure
```
lib/
  main.dart
  theme/app_theme.dart          brand tokens + status color semantics
  models/customer.dart
  models/followup.dart
  db/database_helper.dart       sqflite schema + CRUD
  providers/tracker_provider.dart  app state, derived stats, mutations
  screens/
    root_shell.dart             bottom nav (Follow-ups / Customers / Settings)
    dashboard_screen.dart        stats + grouped upcoming follow-ups
    customers_screen.dart        search + filter chips
    customer_detail_screen.dart  contact card + pending/completed tabs
    followup_detail_screen.dart  appointment, amounts, notes, reschedule history
    settings_screen.dart
  widgets/
    followup_card.dart
    add_followup_sheet.dart      customer picker, date/time picker, amount, notes
    add_customer_sheet.dart
```

## Run it
```
flutter pub get
flutter run
```

## Design notes
- Palette: ink navy (`#16213E`), warm paper (`#F7F4EE`), amber accent
  (`#E8A33D`), teal for completed/success, coral for overdue. See
  `AppColors` in `lib/theme/app_theme.dart`.
- Money amounts are the one place that gets a signature treatment: a short
  amber underline beneath the pending amount on each follow-up card, tying
  the visual language to a ledger/tally feel.
- All screens read from `TrackerProvider`, so swapping sqflite for a remote
  backend later only touches `database_helper.dart`.

## Extending
- Push notifications for due follow-ups: hook into `TrackerProvider.todayCount`
  and schedule local notifications (`flutter_local_notifications`) on app
  start and after `addFollowUp`/`rescheduleFollowUp`.
- Multi-device sync: swap `DatabaseHelper` for a remote data source behind
  the same method signatures — the provider layer doesn't need to change.
