# Cater Pro 2.0 — Phase 4 QA & Release Preparation

## Scope
This phase prepares the Phase 3 source for local QA and release. It does not replace the billing, storage, or synchronization architecture.

## Changes in this phase
- Added a regression test for the existing bill-total rules: `getAllTotalBill()` includes staff bill + other expenses + setting bill, while `getAllTotalTa()` includes staff TA + other expenses and excludes setting bill.
- Added a widget test asserting that Dashboard is the initially selected navigation destination (index 3) while the five destinations remain present.
- Incremented the Android/app package version from `1.0.0+1` to `1.0.1+2` for the next test build.
- Added this release checklist and recorded environment limitations.

## Preserve these rules during QA
- Local save remains the first persistence step; Supabase remains optional and sync-queue based.
- Do not change existing billing formulas, event identifiers, backup schema, or Supabase schema as part of visual polish.
- Validate PDF output and WhatsApp text against a known event before distributing an APK.

## Required commands on a machine with Flutter SDK
Run from the project root:

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

Expected APK path:

`build/app/outputs/flutter-apk/app-release.apk`

## Manual release checklist
- [ ] Launch app: Dashboard is selected initially.
- [ ] Switch Light / Dark / System; kill and relaunch; preference persists.
- [ ] Create an event offline; force close and reopen; event remains saved.
- [ ] Sign in to Supabase and verify queued records sync without duplicate bills.
- [ ] Verify wage, TA, other expenses, and setting bill totals against a hand-calculated event.
- [ ] Generate PDF and verify event name/date, staff groups, expenses, setting bill, and totals.
- [ ] Verify WhatsApp output and sharing target.
- [ ] Restore a backup in a test copy and verify bills, inventory, settlements, and master staff.
- [ ] Test long staff lists and small Android screens for overflow and scrolling.

## Known limitations / not claimed as verified
- Flutter SDK is not installed in the execution environment used to prepare this archive. `flutter analyze`, `flutter test`, and release APK build have therefore **not** been executed here.
- The existing screens still contain some hard-coded light surfaces and text colours. Dark-mode appearance needs manual device verification, especially dialogs, PDF/print previews, and older form sections.
- This archive is a QA candidate, not a certified production release. Do not replace the working production APK until the checklist passes on a device.
