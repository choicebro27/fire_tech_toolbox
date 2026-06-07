# 🔥 Fire Tech Toolbox

A professional-grade mobile app for fire protection technicians, built with Flutter.  
Dark-mode first, compliant with **AS 1670.1** and **AS 1851**.

---

## Features

| Page | Tool | Standards |
|------|------|-----------|
| 1 | **Battery Size Calculator** | AS 1670.1, AS 1851 |
| 2 | **Resistor Colour Code** | EOL resistor reference |
| 3 | **dB Sounder Meter** | AS 1670.1 sound levels |

---

## Project Structure

```
lib/
├── main.dart                        # App entry + bottom nav shell
├── theme/
│   ├── app_theme.dart               # Colours, typography, Material 3 theme
│   └── widgets.dart                 # Shared UI components
└── pages/
    ├── battery_calculator_page.dart # Page 1
    ├── resistor_page.dart           # Page 2
    └── decibel_meter_page.dart      # Page 3
```

---

## Setup & Run

### 1. Prerequisites

- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- For iOS: Xcode ≥ 14, CocoaPods
- For Android: Android Studio, NDK, SDK ≥ 21

### 2. Install dependencies

```bash
flutter pub get
```

### 3. iOS setup

```bash
cd ios && pod install && cd ..
```

The `ios/Runner/Info.plist` already includes the required `NSMicrophoneUsageDescription` key.  
If you already have an `Info.plist`, **merge** the microphone key into it:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Fire Tech Toolbox uses the microphone to measure real-time sound pressure levels
for testing fire alarm sounder compliance with AS 1670.1. No audio is recorded or stored.</string>
```

### 4. Android setup

`AndroidManifest.xml` already includes:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

Minimum SDK is 21 (Android 5.0). Set in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 5. Run

```bash
# Debug
flutter run

# Release (Android)
flutter build apk --release

# Release (iOS)
flutter build ipa --release
```

---

## Page 1 — Battery Size Calculator

### Calculation

```
C_base     = (Iq × Ts) + (Ia × Ta)
C_required = 1.25 × C_base          # AS 1670 25% derating factor
```

| Parameter | Value |
|-----------|-------|
| Ts (Monitored)   | 24 hours |
| Ts (Unmonitored) | 72 hours |
| Ta (default)     | 30 min (0.5 hr) |
| Derating factor  | ×1.25 |

Standard battery sizes checked (Ah):  
`1.2, 2.3, 3.2, 7, 9, 12, 17, 18, 24, 26, 33, 38, 40, 55, 65, 75, 100`

---

## Page 2 — Resistor Colour Code

- Supports **4-band** and **5-band** resistors
- Visual painted resistor updates in real-time
- Full IEC 60062 colour table
- Common EOL values: 2.2 kΩ, 3.3 kΩ, 4.7 kΩ, 5.6 kΩ, 10 kΩ

---

## Page 3 — dB Sounder Meter

### AS 1670.1 Reference Levels

| Requirement | Level |
|-------------|-------|
| Minimum occupiable point | 65 dB(A) |
| 10 dB above ambient | ≥ 75 dB(A) typical |
| Sleeping areas (pillow) | 75 dB(A) |
| Possible hearing damage | > 85 dB |

### Features

- Real-time dB readout with animated glow
- Max / Average tracking
- Calibration offset slider (±10 dB)
- Graceful runtime microphone permission handling

> ⚠️ **Disclaimer:** This tool is indicative only. Use a calibrated Sound Level Meter (Class 1 or 2) for formal compliance certification.

---

## Dependencies

```yaml
noise_meter: ^6.0.0          # Microphone audio level streaming
permission_handler: ^11.3.1  # Runtime permissions (mic)
```

---

## Compliance Notes

- **AS 1670.1-2015** — Design, installation, commissioning and maintenance of fire detection, warning, control and intercom systems
- **AS 1851-2012** — Routine service of fire protection systems and equipment

This app is a **field reference tool** for qualified fire protection technicians.  
It does not replace formal compliance testing, documentation, or certification.

---

## Licence

MIT — Free to use and modify for field work.  
© 2024 Fire Tech Toolbox
