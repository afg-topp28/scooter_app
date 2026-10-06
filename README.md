# Scooter Dashboard

Flutter Android BLE dashboard foundation for Xiaomi/Segway-Ninebot scooters.

## Build

Install Flutter and Android SDK, then:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Important protocol note

BLE discovery/connection is implemented generically. Xiaomi/Ninebot telemetry, lock/unlock, light commands, authentication and encryption are model/firmware specific. `lib/protocol/generic_scooter_protocol.dart` intentionally does not invent packet layouts. Implement a verified protocol adapter for the exact scooter model and BLE firmware before enabling control commands.
