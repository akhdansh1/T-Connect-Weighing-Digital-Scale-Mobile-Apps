## Quick orientation

This is a Flutter mobile app (Android/iOS) for reading weights from Bluetooth scales, creating receipts (resi), exporting history, and printing to Bluetooth ESC/POS printers.

High-level files to open first:
- `lib/main.dart` — app entry, Bluetooth connection, weight parsing, UI, export, and most business logic.
- `lib/bluetooth_printer_helper.dart` — helper that connects to ESC/POS printers and formats receipts (58mm paper).
- `lib/settings_page.dart` — app settings and persistent flags saved with `SharedPreferences` (including `connectionMode`).
- `pubspec.yaml` — dependency versions you must respect (notably `pdf: 3.8.4` and `image: 3.3.0`).

## Big-picture architecture & data flow
- Flutter single-app UI (Material) with stateful `BluetoothPage` in `lib/main.dart`.
- Bluetooth bytes -> ascii.decode -> rawDataLog -> `_parseWeight(data)` -> apply tara via `_applyTara(rawWeight)` -> `currentWeight` (displayed) -> saved to `resiList` / `historyMeasurements` when user taps Save.
- Printing is performed by `BluetoothPrinterHelper.printResi()` which builds ESC/POS bytes using `esc_pos_utils` and sends via `BluetoothConnection`.
- Settings are persisted in `SharedPreferences` keys (see `settings_page.dart` and `main.dart`): e.g. `connectionMode` key toggles continuous/manual read.

## Important conventions & patterns (project-specific)
- Permission model: app requests `bluetoothScan`, `bluetoothConnect`, and `location` at startup in `_requestPermissions()` (`main.dart`). On Android you must ensure runtime permissions are granted.
- Connection modes: `connectionMode` = `continuous` (auto-parse on every incoming chunk) or `manual` (store raw lines; app sends `PRINT\r\n` to request a reading and then parses). See `_connectToDevice`, `_requestData`, and `_parseManualData` in `lib/main.dart`.
- Tara (tare) support: there are two modes — hardware tare (sends `TARE\r\n` to device) and software tare (`_setTaraSoftware()` / `_applyTara()`); `taraValue` is applied during `_parseWeight`.
- In-memory storage: `resiList` and `historyMeasurements` are kept in memory (no persistence). Settings use `SharedPreferences`. There are backup/restore stubs in `settings_page.dart` but file-based restore is marked "in development".

## Notable implementation details & gotchas for contributors
- Weight parsing: `_parseWeight(String data)` extracts the first numeric token via regex and converts to double. It then calls `_applyTara()` — so any calibration factor is NOT automatically applied to parsed values (calibrationFactor is saved in `_performCalibration` but not used in `_parseWeight`). If you change parsing, check this gap.
- Commands to/from scale:
  - Request a sample: app sends `PRINT\r\n` (`_requestData`).
  - Tare hardware: app sends `TARE\r\n` in `_setTara()` if connected.
  - Unit change commands are sent as `UNIT:KG\r\n`, `UNIT:G\r\n`, `UNIT:LB\r\n`, etc. See `_changeUnit()`.
- ESC/POS printing: `BluetoothPrinterHelper` uses `CapabilityProfile.load()` and `Generator(PaperSize.mm58, profile)` — expect 58mm receipts and the `esc_pos_utils` flow. Tests or device-specific fixes often revolve around encoding or paper size.

## Dev workflows & quick commands
- Install deps and analyze:
  - flutter pub get
  - flutter analyze
- Run on a connected Android device (Windows PowerShell):
  - flutter run -d <device_id>
- Build a release APK:
  - flutter build apk --release

Notes for device testing:
- Pair the scale in Android Settings (Bluetooth pairing) before running the app. The app reads bonded devices via `FlutterBluetoothSerial.getBondedDevices()`.
- If Bluetooth permissions fail, re-check runtime permissions and AndroidManifest for required permissions (this project requests them at runtime in code).

## Where to look when modifying behavior
- Add or change parsing logic: `lib/main.dart` -> `_parseWeight`, `_parseManualData`, and `_connectToDevice` (listeners).
- Change print layout: `lib/bluetooth_printer_helper.dart` -> `printResi()` (uses `esc_pos_utils` generator rows and styles).
- Change settings persistence: `lib/settings_page.dart` and `_loadConnectionMode()` in `lib/main.dart` (SharedPreferences keys like `connectionMode`).

## Quick examples you can cite in code edits
- To trigger a manual read: call `_requestData()` — it sends `PRINT\r\n` and, if in manual mode, waits 500ms then calls `_parseManualData()`.
- To add a hardware command: use `connection!.output.add(Uint8List.fromList('YOURCMD\r\n'.codeUnits));` (pattern used for `TARE` and `PRINT`).

## Tests & next steps for automation
- There are no domain unit tests. Add lightweight tests for:
  - `_parseWeight` behavior (happy path + malformed input).
  - `_applyTara` and calibration interplay.
  - `BluetoothPrinterHelper.printResi()` can be split into a pure-formatting function returning bytes for easier unit testing.

## Questions for the maintainer (for follow-up)
- Should `historyMeasurements` and `resiList` be persisted (sqflite is present in `pubspec.yaml` but not used)?
- Should `calibrationFactor` be applied automatically when parsing weights?

If anything here is unclear or you want me to expand a specific section (examples, tests, or CI steps), tell me which area and I will iterate.
