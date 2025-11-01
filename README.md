# TJ Restock MVP

Private MVP: Flutter-based iOS app to scan barcodes in-aisle and auto-build a restock pick-list with CSV export.

**Version:** 1.0.0  
**Spec:** see [`docs/spec_v1.1.md`](docs/spec_v1.1.md)

## Overview

This app helps Trader Joe's section leads replace handwritten restock lists with a mobile, barcode-driven workflow. Walk a section once, scan shelf/item barcodes, and auto-build a digital pick-list grouped by section. The app is offline-first, exports CSV, and runs without App Store via local sideloading.

## Features

- **Barcode Scanning**: Supports UPC-A/EAN-13, Code 128, and QR codes
- **Manual Entry**: Fallback option when barcodes can't be scanned
- **Section Management**: 19 predefined Trader Joe's sections
- **Offline-First**: Complete functionality without internet connection
- **CSV Export**: Share via iOS Share Sheet with auto-save fallback
- **Quantity Management**: Easy increment/decrement with haptic feedback
- **Duplicate Detection**: 1.5s debounce with quick +1 option
- **Undo Support**: 2-second undo window for accidental scans

## Requirements

### Development Environment
- **macOS** with Xcode 14+ installed
- **Flutter SDK** 3.35.7 or later
- **iOS Device** running iOS 16+ with Developer Mode enabled
- **Apple ID** (free account works for 7-day provisioning)

### Device Setup
1. Enable Developer Mode on your iPhone:
   - Go to **Settings → Privacy & Security → Developer Mode**
   - Toggle Developer Mode ON
   - Restart your device when prompted

## Installation & Setup

### 1. Install Flutter (if not already installed)

```bash
# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Clone and Setup Project

```bash
# Navigate to project directory
cd tj_restock_mvp

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. iOS Configuration in Xcode

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Configure Signing:
   - Select **Runner** in the project navigator
   - Go to **Signing & Capabilities** tab
   - Select your **Personal Team** from the Team dropdown
   - Set a unique **Bundle Identifier** (e.g., `com.yourname.tjrestock`)

3. Connect your iPhone:
   - Plug in your iPhone via USB
   - Unlock the device and tap **Trust This Computer**

### 4. Build and Run

#### Option A: Using Xcode
1. Select your iPhone as the target device
2. Click the **Run** button (▶) or press `Cmd+R`

#### Option B: Using Flutter CLI
```bash
# List available devices
flutter devices

# Run on your device
flutter run -d <device-id>
```

### 5. Trust the Developer Certificate

First time running the app:
1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Find your Apple ID under **Developer App**
3. Tap and select **Trust**
4. Confirm by tapping **Trust** again

## Usage Guide

### Basic Workflow

1. **Select Section**
   - Launch the app
   - Choose your section from the list (e.g., "Grocery", "Frozen")
   - Tap "Start Scanning"

2. **Scan Items**
   - Point camera at barcode
   - App automatically adds items with haptic feedback
   - Use torch toggle for low-light conditions
   - Tap "Manual Entry" if barcode can't be scanned

3. **Manage Quantities**
   - Duplicate scans show "+1" option
   - View pick list to adjust quantities
   - Swipe left to delete items

4. **Export Pick List**
   - Tap "View Pick List" button
   - Review all scanned items grouped by section
   - Tap "Export CSV"
   - Share via AirDrop, Messages, or save to Files
   - Optionally clear list after export

### Camera Issues Troubleshooting

If you see a **black screen** instead of camera preview:

1. **Check Permissions**:
   - Go to iPhone **Settings → TJ Restock MVP**
   - Ensure Camera permission is enabled

2. **Restart the App**:
   - Force quit and relaunch the app

3. **Check Developer Mode**:
   - Ensure Developer Mode is still enabled in Settings

4. **Rebuild the App**:
   - Sometimes a fresh build resolves camera initialization issues
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Verify Info.plist**:
   - Ensure `NSCameraUsageDescription` is present in `ios/Runner/Info.plist`
   - This should already be configured in the project

### CSV Export Format

Exported CSV files include:
```csv
timestamp,section,barcode_or_text,label,qty
2025-10-31T10:22:45-04:00,Grocery,012345678905,"TJ's Pasta Sauce",2
2025-10-31T10:23:07-04:00,DFN,manual:"Pumpkin Seeds – Salted",,1
```

Files are saved to the app's Documents directory and can be accessed via the Files app.

## Sections List

The app includes 19 predefined Trader Joe's sections:
- Dry Produce (Dry Pro)
- Wet Produce (Wet Pro)
- Fresh
- Milk/Yogurt (Box)
- Meat
- Cut Cheeses
- Flowers
- Coffee & Tea
- Cookie & Candy
- Snacks
- Bread
- DFN (Dried Fruit & Nuts)
- Beverage
- Beer & Wine
- HABA (Health & Beauty)
- Deli/Dips
- Grocery
- Frozen
- Eggs

## Free Provisioning Limitations

When using a free Apple ID:
- Apps expire after **7 days**
- You'll need to rebuild and reinstall weekly
- Maximum of **3 apps** can be installed at once
- No push notifications or certain advanced features

To rebuild after expiration:
```bash
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── section.dart
│   └── pick_entry.dart
├── services/                 # Business logic
│   ├── db_service.dart
│   ├── barcode_scanner.dart
│   ├── mobile_scanner_adapter.dart
│   ├── export_service.dart
│   └── haptics_service.dart
├── state/                    # State management
│   └── app_state.dart
├── screens/                  # UI screens
│   ├── sections_screen.dart
│   ├── scanner_screen.dart
│   └── picklist_screen.dart
└── widgets/                  # Reusable widgets
    └── manual_entry_sheet.dart
```

## Technical Details

### Dependencies
- **mobile_scanner** ^5.2.3 - Barcode scanning
- **hive** ^2.2.3 - Local database
- **flutter_riverpod** ^2.6.1 - State management
- **csv** ^6.0.0 - CSV generation
- **share_plus** ^10.1.2 - iOS Share Sheet
- **path_provider** ^2.1.4 - File system access
- **uuid** ^4.5.1 - Unique ID generation

### Scanner Abstraction

The app uses a scanner abstraction layer (`BarcodeScanner` interface) that allows easy swapping of barcode scanning engines:
- Current: `MobileScannerAdapter` (mobile_scanner package)
- Future options: Google ML Kit, Scandit, or other commercial SDKs

### Performance Targets
- Median decode time: <300ms
- First-pass decode rate: ≥90% (target ≥95%)
- Rescan rate: ≤10%
- UI frame rate: 60 fps

## Known Issues

1. **Analyzer Warnings**: Minor deprecation warnings for Radio widget properties (Flutter 3.35.7) - these don't affect functionality
2. **iOS Simulator**: Camera scanning won't work in simulator - requires physical device
3. **7-Day Expiration**: Free provisioning requires weekly rebuilds

## Support & Feedback

For issues or questions:
- Check the troubleshooting section above
- Review the full specification in `docs/spec_v1.1.md`
- Ensure all iOS permissions are granted

## License

Private MVP for internal use. Not for distribution.

## Version History

### v1.0.0 (2025-10-31)
- Initial MVP release
- Barcode scanning with UPC-A/EAN-13/Code 128 support
- Manual entry fallback
- 19 predefined sections
- CSV export with Share Sheet + auto-save
- Offline-first functionality
- Proper camera initialization to prevent black screen issues
