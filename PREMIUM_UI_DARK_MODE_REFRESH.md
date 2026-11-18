# Staff Billing App — Premium UI & Dark Mode Refresh

## Design system

- Light theme: warm off-white canvas, deep teal primary surfaces, white cards and restrained mint-green success accents.
- Dark theme: deep teal/charcoal canvas, elevated teal surfaces, mint primary actions and readable muted foregrounds.
- Shared Material 3 styling for app bars, cards, forms, buttons, dialogs, bottom sheets, dividers and progress indicators.
- Rounded, floating bottom navigation with an animated selected state.
- Consistent card borders, spacing and subtle elevation across the app.

## Screens covered

- Dashboard: teal hero panel, theme quick-toggle, shared analytics cards and updated navigation styling.
- Reporting: theme quick-toggle, themed attendance/table surfaces and rounded staff-entry cards.
- Outing Billing: themed wage dialogs, staff/group cards, expense inputs, totals footer and WhatsApp sheet.
- Events: shared card, form, dialog and button styling through the global theme.
- Calendar: themed calendar surfaces and date/event states.
- Staff Directory / Other: themed staff cards, inventory, settlement surfaces and appearance settings.
- Shared staff and outing row widgets: rounded card rows and dark-aware attendance/status fields.

## Appearance options

- Light mode
- Dark mode (first-launch default)
- System default

The existing SharedPreferences key is retained, so a previously saved Light/Dark choice is not discarded. Theme selection remains persisted across launches. Dashboard and Reporting provide quick Light/Dark toggles; the Staff Directory appearance sheet also provides System default.

## Data and business logic

This refresh is limited to presentation and theme handling. It does not intentionally change staff calculations, wage/TA formulas, bill totals, local storage models, backup/restore, PDF generation or Supabase sync logic.

## Verification

The Flutter and Dart SDKs are not installed in the editing environment. Therefore `flutter analyze`, `flutter test` and Android release build could not be run here. Run these in the project's Flutter environment before publishing:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
