# easy_pill
Pill Tracker on Flutter

## Overview
Easy Pill is a Flutter app to help users manage medications, schedules, and synchronization across devices. It uses Provider for state management, Firebase for optional auth/sync, and a centralized design system via `AppColors`.

## Architecture (UML)
The high-level architecture and relationships are captured in a PlantUML diagram:

- Diagram source: `assets/architecture.puml`
- To render locally:

```bash
plantuml assets/architecture.puml -o assets
```

Key modules:
- `lib/models`: core data types like `Medication`, `SyncConflict`.
- `lib/providers`: `AuthProvider`, `MedicationProvider`, `SyncProvider`, `LocalizationProvider`.
- `lib/screens`: UI pages (`HomeScreen`, `LoginScreen`, `SignUpScreen`, `AccountScreen`, `LocationsScreen`, `SyncConflictScreen`).
- `lib/widgets`: reusable UI components (`AddMedicationModal`, `MedicationCard`, `ActionButton`, etc.).
- `lib/utilities`: `AppColors`, `InputFormatters`, localization extensions.

## Localization
- Strings are accessed via `context.tr('key')` or `localizationProvider.tr('key')`.
- Recent updates localized `locations.dart` and `sync_conflict_screen.dart` option labels and messages.

## Input Validation
- Email fields (Login/Signup) enforce lowercase and no spaces via `AppInputFormatters.email`.
- Pill total and interval fields use digits-only via `AppInputFormatters.digitsOnly`.

## Theming
- Centralized palette in `lib/utilities/app_colors.dart`.
- `main.dart` uses these colors in `ThemeData`.

## Development
Run analyzer and tests:

```bash
flutter analyze
flutter test
```

Optional: render the UML if you have PlantUML installed.

```bash
plantuml assets/architecture.puml -o assets
```

## Notes
- Firebase is optional; the app runs without authentication for local usage.
- Sync features require proper `.env` configuration and Firebase setup.
