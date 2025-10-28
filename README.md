# TJ Restock MVP

This project implements a minimal **scan‑to‑pick‑list** application per the `spec_v1.1.md`. It targets **iOS 16+** and uses Flutter with Riverpod for state management. Users select a store section, scan barcodes (with haptic feedback and duplicate debounce), build a pick list with editable quantities, and export the list to CSV via the Share Sheet. The export service automatically saves a copy of the CSV in the device’s Documents directory.

## Features

* **Section selection:** Choose from a seeded list of sections (Dry Produce, Wet Produce, Fresh, Milk/Yogurt, Meat).
* **Barcode scanning:** Uses `mobile_scanner` with torch toggle and haptic feedback. Duplicate scans are ignored within a 1.5‑second window. A manual entry dialog is available when scanning fails.
* **Pick list:** Items are grouped by section. Quantities can be edited inline; swipe to delete removes an entry. Export to CSV via `share_plus`; a confirmation dialog asks if the list should be cleared after export.
* **Services:**
  * `scanner_service` implements a `BarcodeScanner` abstraction using `mobile_scanner`.
  * `db_service` persists sections and picks in local storage via Hive.
  * `export_service` converts picks to CSV, writes a backup file to the Documents directory, and invokes the Share Sheet.
  * `haptics_service` triggers light haptic feedback on successful scans.
* **Tests:** Unit and widget tests cover CSV round‑trip and auto‑save, pick list state (add/edit/delete), and debounce logic.
* **CI:** GitHub Actions workflow installs Flutter, runs `flutter analyze` and `flutter test`, and on pushes to `main` builds an Android debug APK and uploads it as an artifact.

## Running on iPhone (free provisioning)

1. **Set up your environment:** Install the latest Flutter SDK and Xcode (with iOS 16+ SDK) on your Mac. Enable **Developer Mode** on your iPhone (Settings → Privacy & Security → Developer Mode).
2. **Clone the repository and fetch dependencies:**
   ```bash
   git clone <repo-url>
   cd <repo>/mvp_app
   flutter pub get
   ```
3. **Open in Xcode:** Run `open ios/Runner.xcworkspace` to launch the Xcode workspace. In the *Signing & Capabilities* tab, set your personal Apple ID as the *Team*. Xcode will create a free provisioning profile and bundle identifier.
4. **Run the app:** Connect your iPhone, select it as the run target in Xcode, and press the *Run* button. Alternatively, you can use `flutter run -d <device-id>`.
5. **Use the app:** Select a section, scan items (torch toggle and haptic feedback supported), or use **Manual Entry**. Review your pick list, adjust quantities inline, swipe to delete, and tap the upload icon to export. The CSV is auto‑saved to the Documents directory even if you cancel the Share Sheet. Optionally clear the list after export.

## License

This project is provided for demonstration purposes and is not licensed for production use.