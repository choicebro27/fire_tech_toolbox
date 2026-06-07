# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Fire Tech Toolbox is a Flutter mobile app (iOS + Android) for fire protection technicians. It provides:
- **Battery Size Calculator** (free) — AS 1670.1/AS 1851 compliant sizing
- **Resistor Colour Code** (Pro) — 4/5-band IEC 60062 decoder with EOL reference values
- **dB Sounder Meter** (Pro) — real-time microphone meter with AS 1670.1 reference levels
- **Standards AI Chat** (Pro) — on-device RAG using Gemma 2B-IT over user-uploaded standard PDFs

## Common commands

```bash
# Install dependencies
flutter pub get

# iOS pod install (required after pub get on iOS)
cd ios && pod install && cd ..

# Run on connected device/simulator
flutter run

# Static analysis (lints via flutter_lints)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release
flutter build apk --release   # Android
flutter build ipa --release    # iOS
```

## Architecture

### Navigation shell (`lib/main.dart`)
`_HomeShell` is a `BottomNavigationBar` shell that uses `IndexedStack` with six tabs. Pro-gated tabs are wrapped in `PaywallOverlay`, which blurs the child page and shows a purchase sheet until `EntitlementService.isPro` is true.

### Services (singletons, all via `.instance`)
All services are initialised sequentially in `main()` before `runApp`:

| Service | File | Responsibility |
|---|---|---|
| `EntitlementService` | `services/entitlement_service.dart` | Persists Pro unlock state to `shared_preferences`. Single source of truth for `isPro`. |
| `PurchaseService` | `services/purchase_service.dart` | Wraps `in_app_purchase`. Handles buy/restore flow. Calls `EntitlementService.unlock()` on confirmed purchase. Product ID constant `kProProductId` must match the store listing. |
| `GemmaService` | `services/gemma_service.dart` | Wraps `flutter_gemma` v0.3.x. Downloads Gemma 2B-IT TFLite from HuggingFace on demand, caches to device. Runs RAG: retrieves chunks from `StandardsDb`, builds instruction-tuned prompt, streams tokens. |
| `StandardsDb` | `services/standards_db.dart` | SQLite (sqflite) database with FTS5 full-text search. Stores text chunks extracted from user-uploaded standard PDFs. Two tables: `chunks` + `standards_meta`. FTS kept in sync via triggers. |

### Theme system (`lib/theme/`)
- `AppTheme` / `AppColors` — all colour tokens. Both dark and light palettes defined. Dark is the default.
- `ThemeModeNotifier` — `ChangeNotifier` holding current `ThemeMode`, wrapped in `AppThemeScope` (`InheritedNotifier`).
- `BuildContext` extension `ThemeColors` — use `context.appBackground`, `context.appSurface`, etc. for colour resolution. Prefer these over `Theme.of(context)` for custom colours.
- `lib/theme/widgets.dart` — shared components: `TechCard`, `ResultRow`, `InfoBox`, `AccentBadge`.

### Paywall pattern
Wrap any locked page in `PaywallOverlay`:
```dart
PaywallOverlay(
  featureName: 'Feature Name',
  features: ['bullet 1', 'bullet 2'],
  child: YourPage(),
)
```
`PaywallOverlay` listens to `EntitlementService` and renders the child directly once Pro is unlocked.

### AI Chat / RAG flow
1. User uploads a PDF → `PdfIndexer` extracts text by page, detects clause refs (regex), splits into ~500-char chunks → `StandardsDb.insertChunks()`
2. User asks a question → `GemmaService.ask()` → FTS5 keyword search → top 4 chunks → Gemma instruction prompt → token stream
3. Gemma 2B-IT uses format: `<start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n`

## Key configuration points

- **In-app purchase product ID**: `kProProductId` in `lib/services/purchase_service.dart` — must be updated to match the actual bundle ID before store submission.
- **`EntitlementService.debugRevoke()`**: Dev helper to reset Pro unlock — remove before shipping.
- **Microphone permission**: `NSMicrophoneUsageDescription` in `ios/Runner/Info.plist`, `RECORD_AUDIO` in `android/app/src/main/AndroidManifest.xml`.
- **Min Android SDK**: 21 (set in `android/app/build.gradle.kts`).

## Battery calculator formula

```
C20 = 1.25 × ((Iq × Tq) + Fc × (Ia × Ta))   where Fc = 2
```
- Tq: 24h (monitored) or 72h (unmonitored)
- Ta: default 30 min (0.5h); Fc = 2 (fixed capacity derating factor)
- Standard battery sizes (Ah): 1.2, 2.3, 3.2, 7, 9, 12, 17, 18, 24, 26, 33, 38, 40, 55, 65, 75, 100
