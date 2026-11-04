# Cater Pro UI update — 2026-11-04

## Changes implemented
- Replaced the six-destination bottom navigation with five destinations: Reporting, Outing, Dashboard, Manage and Events.
- Added a More bottom sheet with Calendar access; the Calendar screen remains in the existing IndexedStack and its state is retained.
- Kept the existing page indexes, bill loading, auto-save callbacks, event navigation and staff/billing workflows intact.
- Updated the dark theme foundation to the requested navy/lavender palette and made dark mode the default for new installs and previously selected System mode. An explicitly selected Light mode is still respected.
- Redesigned Events into a compact two-column grid. Each event tile shows only Site Name and Date; tapping opens the requested Event Details / Staff Count / Total TA summary.
- Preserved the existing event overflow actions: Open Bill / Manage Staff, Edit and Delete.
- Updated Calendar cards, dialogs and text colors to use the active theme instead of forcing white surfaces.
- Removed the invalid const use on the Outing Billing row decoration that was reported by the supplied analyzer log.
- Updated widget tests for the five-destination navigation and Calendar in More.

## Verification
- ZIP contents and source files were inspected.
- Flutter/Dart SDK is not installed in this editing environment, so `flutter analyze`, `flutter test`, and release APK build could not be run here.
- Run the GitHub Actions workflow after pushing this source ZIP's contents. The workflow will still fail if any additional compile-time issue remains; do not treat this note as a successful build claim.

## Important
No model, calculation, storage, PDF, WhatsApp or Supabase service implementation was intentionally changed.
