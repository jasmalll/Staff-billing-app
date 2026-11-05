# CaterPro implementation notes — 5 Nov 2026

## Project inspection
- Updated the existing `billing` Flutter application in place; no project replacement or database migration was introduced.
- Existing app structure is retained: screens, models, local SharedPreferences storage, durable cloud-sync queue, optional Supabase service, PDF services, and backup/restore services.
- The supplied ZIP contains 231 archive entries and an existing Flutter application with Android, Web, iOS, desktop targets, tests, and Supabase setup assets.

## Changes
- Reporting is the initial navigation destination.
- Added a Dashboard top-bar Calendar action beside Manage Staff. It opens the existing full Calendar screen.
- Events now contains only the Event List; the Calendar screen and its data operations remain intact and are reachable from Dashboard.
- Replaced the three large Reporting KPI tiles with compact live Present/Absent indicators and a staff count.
- Tightened Reporting staff row spacing and Outing staff row spacing.
- Entering a positive TA now transitions a staff member to Present. The state update is guarded so repeated keystrokes do not repeatedly change attendance. Zero/negative TA does not trigger automatic attendance. Manual attendance toggling remains available.
- Added widget coverage for positive/zero TA behavior, initial Reporting destination, Dashboard Calendar navigation, and the single Events list.

## Data safety
- No storage keys, serialized model fields, Supabase tables, conflict keys, or backup schema were changed.
- No data reset, migration, or bulk rewrite was added.

## Validation limitation
- `flutter` and `dart` executables are not installed in this execution environment. Therefore `flutter pub get`, `flutter analyze`, `flutter test`, Android release build, and Flutter Web build could not be executed here. They are not represented as passing.
