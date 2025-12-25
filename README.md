# T-Connect - Weighing Digital Scale Mobile App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Flutter mobile app for digital weighing scales with Bluetooth & USB connectivity.

## Features

✅ Bluetooth & USB Serial connection
✅ Real-time weight monitoring
✅ SQLite local database
✅ Label printing (TSPL & ESC/POS)
✅ Statistical weighing mode
✅ Demo mode (no scale required)
✅ Product management with counting mode
✅ Custom field configuration
✅ Export to CSV/PDF

## Screenshots

[Add screenshots here]

## Installation
```bash
flutter pub get
flutter run
```

## Tech Stack

- Flutter 3.x
- SQLite (sqflite)
- Bluetooth (flutter_bluetooth_serial)
- USB Serial (usb_serial)
- PDF generation (pdf, printing)
```

---

### 2️⃣ **Add .gitignore entries** (if needed)

Make sure your `.gitignore` has:
```
# Flutter
build/
.dart_tool/
.packages
.pub/

# IDE
.vscode/
.idea/
*.iml

# Android
*.jks
key.properties

# Secrets
.env