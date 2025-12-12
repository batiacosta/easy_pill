# easy_pill (Flutter)

Pill tracker built with Flutter. Supports local use out of the box and optional Firebase sync/auth when configured.

## Prerequisites
- Flutter SDK (3.24+ recommended)
- Java 17 (required by recent AGP)
- Xcode for iOS builds (macOS) / Android Studio for Android builds
- CocoaPods (macOS) if you plan to build/run on iOS

## Quick start
```bash
git clone <repo-url>
cd easy_pill
flutter pub get
flutter run            # picks a connected device or emulator

# Platform-specific builds
flutter build apk      # Android
flutter build ios      # iOS (on macOS with signing set up)
```

### Optional: Firebase sync/auth
1) Create a Firebase project (Auth + Firestore).
2) Add platform configs: `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
3) Ensure FlutterFire plugins are initialized in `lib/main.dart` (already scaffolded for optional use).

## Entry point
- `lib/main.dart` — boots the app, sets up Provider scopes, theming, and routes.

## Project structure (what matters)
- `lib/models/`
	- Data types: `Medication`, `ScheduledDose`, sync conflict models.
- `lib/providers/`
	- State & services wiring: `AuthProvider`, `MedicationProvider` (dosing, notifications, local DB), `SyncProvider`, `LocalizationProvider`.
- `lib/services/`
	- `database_service.dart` (sqflite), `notification_service.dart`, `firestore_service.dart`, `notification` setup.
- `lib/screens/`
	- UI pages: `home.dart` (dashboard of today/scheduled/missed), `login.dart`, `signup.dart`, `account.dart`, `locations.dart`, `sync_conflict_screen.dart`.
- `lib/widgets/`
	- Reusable UI: dose cards, headers, options sheets, add/edit medication modal.
- `lib/utilities/`
	- `app_colors.dart`, formatters, localization extensions.
- `assets/`
	- `architecture.puml` (PlantUML diagram), app icons.
- `android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/`
	- Platform scaffolding managed by Flutter.

## Common dev commands
- Lint: `flutter analyze`
- Tests: `flutter test`
- Refresh packages: `flutter pub upgrade --major-versions`
- Show outdated: `flutter pub outdated`

## Notes
- Works offline with local storage; Firebase is optional.
- Notifications rely on scheduling per medication; ensure device-level permissions are granted.
- For Android builds, AGP 8.9.1 + Gradle 8.11.1 are configured; Kotlin 2.1.0 is used.

## UML (optional)
- Source: `assets/architecture.puml`
- Render (if PlantUML installed): `plantuml assets/architecture.puml -o assets`
