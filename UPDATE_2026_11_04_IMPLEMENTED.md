# Cater Pro update — 04 Nov 2026

## Implemented in this source update

- Events cards now show only Site Name and Date in compact side-by-side tiles. Tapping a card opens the copyable details summary in the requested order: Site name, Date, Event, Staff Count, and Total TA. Existing Edit, Delete, and Open Bill actions remain in the overflow menu.
- Main navigation now has Reporting, Outing, Dashboard, Manage, and Events, with Calendar moved into a More bottom sheet. All six screen widgets remain in the IndexedStack.
- Removed the dashboard Event Management card's Open affordance; the event summary remains visible and Events is available from bottom navigation.
- Reporting edits now also rebuild the parent navigation shell, so the Outing screen receives attendance changes immediately rather than waiting for a tab switch. The existing rule remains: only the green check is Present; every other state is Absent.
- Tightened the Outing metadata form spacing and updated key Outing surfaces to follow the active theme.
- Updated the dark theme foundation to the premium navy/lavender palette (navy background and readable dark surfaces).
- Updated the widget tests for the five-destination navigation and More menu.
- Android Gradle wrapper in this archive is already set to Gradle 8.14.3, above Flutter's stated 8.14.0 minimum. Android Gradle Plugin remains 8.11.1 (not AGP 9).

## Verification status

The source archive was inspected and edited. Flutter/Dart SDK is not installed in this execution environment, so `flutter analyze`, `flutter test`, and `flutter build apk --release` could not be run here. Run those three commands in GitHub Actions or a Flutter-enabled machine before installing the APK. Do not treat the project as release-verified until those checks pass.
