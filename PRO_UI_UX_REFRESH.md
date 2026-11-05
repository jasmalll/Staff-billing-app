# Cater Pro – Pro UI/UX refresh

## UX review and decisions

- The previous navigation exposed Reporting, Outing, Calendar, Dashboard, Manage and Events as six crowded destinations.
- The refreshed shell exposes exactly four primary destinations: Dashboard, Reporting, Outing and Events.
- Calendar is now a first-class second tab inside Events (`Event List` / `Calendar`), so date-based event browsing remains directly accessible without a duplicate navigation route.
- Staff Directory / Manage remains available from the Dashboard app-bar staff action. Existing staff, inventory, settlement and theme functionality is retained in `OtherScreen`.
- Dashboard analytics remain derived from persisted `CateringBill` data and existing calculation methods. No billing, wage, TA, expense, database or storage formulas were rewritten.
- Analytics metric tiles now use a reusable glassmorphic component with restrained blur, translucent surfaces and subtle border/elevation.

## Main files changed

- `lib/main.dart` – four-destination navigation shell and route mapping.
- `lib/screens/dashboard_screen.dart` – Manage entry point and reusable premium analytics tiles.
- `lib/screens/events_screen.dart` – integrated Event List / Calendar tab switcher.
- `lib/screens/calendar_screen.dart` – embedded mode for use inside Events, preserving standalone mode and backup/restore actions.
- `lib/widgets/premium_components.dart` – reusable `GlassmorphicCard`, `MetricPill` and `AnalyticsItem`.
- `test/widget_test.dart` – navigation and integrated calendar expectations updated.

## Verification status

The source package was inspected and edited, but Flutter/Dart SDK binaries are not available in this execution environment. Therefore `flutter analyze`, `flutter test`, `flutter build apk --release` and `flutter build web --release` have **not** been executed here. The existing GitHub Actions workflows remain the authoritative compile/test verification. Do not treat this package as build-verified until both workflows complete successfully.
