# Camera Troubleshooting Guide

This guide addresses the camera black screen issue that was encountered in previous builds and provides comprehensive troubleshooting steps.

## The Black Screen Issue

### What Causes It?

The "green light on, but black screen" issue typically occurs due to:

1. **Missing Camera Permissions**: iOS requires explicit permission declarations in Info.plist
2. **Improper Camera Initialization**: The camera controller must be properly initialized before use
3. **Lifecycle Management**: Camera must be properly started, stopped, and disposed
4. **Permission Denial**: User denied camera access or permissions weren't requested
5. **Device Trust Issues**: Developer certificate not trusted on device

## How This Implementation Fixes It

### 1. Proper Info.plist Configuration

The `ios/Runner/Info.plist` file includes the required camera permission:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan barcodes and build your restock list.</string>
```

This ensures iOS prompts the user for camera access on first launch.

### 2. Correct Camera Initialization

The `MobileScannerAdapter` properly initializes the camera:

```dart
MobileScannerAdapter()
    : _controller = ms.MobileScannerController(
        detectionSpeed: ms.DetectionSpeed.normal,
        facing: ms.CameraFacing.back,
        torchEnabled: false,
      )
```

Key points:
- Controller is created before use
- Proper camera facing (back camera)
- Torch initially disabled

### 3. Proper Lifecycle Management

The `ScannerScreen` properly manages camera lifecycle:

```dart
@override
void initState() {
  super.initState();
  _scannerAdapter = MobileScannerAdapter();
  _initScanner();
}

Future<void> _initScanner() async {
  await _scannerAdapter.start();
  _scanSubscription = _scannerAdapter.results.listen(_handleScanResult);
}

@override
void dispose() {
  _scanSubscription?.cancel();
  _scannerAdapter.dispose();
  super.dispose();
}
```

This ensures:
- Camera starts when screen opens
- Subscription is properly managed
- Camera is disposed when screen closes

### 4. Using MobileScanner Widget

The scanner screen uses the `MobileScanner` widget directly:

```dart
MobileScanner(
  controller: _scannerAdapter.controller,
  onDetect: (capture) {
    // Handle barcode detection
  },
)
```

This provides a proper camera preview that displays correctly.

## Troubleshooting Steps

### Step 1: Check Camera Permissions

1. Open **Settings** on your iPhone
2. Scroll down and find **TJ Restock MVP**
3. Tap on it
4. Ensure **Camera** is toggled ON (green)

If the app isn't listed:
- The app hasn't requested permissions yet
- Launch the app and grant permission when prompted

### Step 2: Verify Developer Mode

1. Go to **Settings → Privacy & Security → Developer Mode**
2. Ensure Developer Mode is **ON**
3. If you just enabled it, restart your iPhone

### Step 3: Trust Developer Certificate

1. Go to **Settings → General → VPN & Device Management**
2. Find your Apple ID under **Developer App**
3. Tap it and select **Trust**
4. Confirm by tapping **Trust** again

### Step 4: Force Quit and Restart

1. Swipe up from bottom (or double-click Home button)
2. Find TJ Restock MVP
3. Swipe up to close it
4. Relaunch the app

### Step 5: Rebuild the App

Sometimes a fresh build resolves initialization issues:

```bash
cd tj_restock_mvp
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d <device-id>
```

### Step 6: Check Xcode Console

If the issue persists, check Xcode console for errors:

1. Open Xcode
2. Go to **Window → Devices and Simulators**
3. Select your iPhone
4. Click **Open Console**
5. Look for camera-related errors

Common errors and solutions:
- `AVCaptureSessionRuntimeErrorNotification`: Camera in use by another app - close other camera apps
- `Permission denied`: Check Info.plist and app permissions
- `Device not available`: Restart iPhone

### Step 7: Test on Different Device

If possible, test on another iPhone to rule out device-specific issues.

## Prevention Best Practices

### For Developers

1. **Always declare permissions in Info.plist**
   - NSCameraUsageDescription is mandatory
   - Provide clear, user-friendly descriptions

2. **Initialize camera properly**
   - Create controller before use
   - Start camera in initState or onResume
   - Stop camera in dispose or onPause

3. **Handle permission denial gracefully**
   - Check permission status before accessing camera
   - Show helpful message if denied
   - Provide link to Settings

4. **Test on physical devices**
   - Camera doesn't work in iOS Simulator
   - Always test camera features on real iPhone

5. **Manage camera lifecycle**
   - Dispose controllers properly
   - Cancel subscriptions
   - Handle app backgrounding

### For Users

1. **Grant camera permission when prompted**
   - App cannot function without camera access
   - Permission can be changed later in Settings

2. **Keep Developer Mode enabled**
   - Required for sideloaded apps
   - Don't disable after installation

3. **Rebuild weekly**
   - Free provisioning expires after 7 days
   - Rebuild before expiration to avoid issues

4. **Close other camera apps**
   - Only one app can use camera at a time
   - Force quit other apps if needed

## Technical Details

### Camera Initialization Flow

1. App launches → `main()` initializes database
2. User navigates to ScannerScreen
3. `initState()` creates `MobileScannerAdapter`
4. `_initScanner()` starts camera controller
5. Camera preview appears in `MobileScanner` widget
6. Barcode detection begins automatically

### Permission Request Flow

1. First camera access attempt
2. iOS shows permission dialog
3. User grants or denies
4. Result stored in iOS settings
5. Subsequent launches use stored permission

### Why This Works

The implementation uses the `mobile_scanner` package which:
- Properly wraps iOS AVFoundation camera APIs
- Handles permission requests automatically
- Provides a widget that displays camera preview
- Manages camera lifecycle correctly
- Supports torch, zoom, and other features

## Still Having Issues?

If you've tried all troubleshooting steps and still see a black screen:

1. **Check iOS version**: Ensure iOS 16+ is installed
2. **Check Flutter version**: Ensure Flutter 3.35.7+ is installed
3. **Check package versions**: Run `flutter pub outdated` to check for updates
4. **Review Xcode logs**: Look for specific error messages
5. **Try a different barcode scanner package**: The abstraction layer allows easy swapping

### Alternative Scanner Packages

If mobile_scanner doesn't work, you can try:

1. **google_mlkit_barcode_scanning**
   - Google's ML Kit
   - More robust but larger size

2. **qr_code_scanner**
   - Simpler implementation
   - Good for QR codes

3. **ai_barcode_scanner**
   - AI-powered scanning
   - Better accuracy in poor lighting

To swap scanners, implement a new adapter for the `BarcodeScanner` interface in `lib/services/barcode_scanner.dart`.

## Summary

The camera black screen issue has been addressed through:
- ✅ Proper Info.plist configuration
- ✅ Correct camera controller initialization
- ✅ Proper lifecycle management
- ✅ Using MobileScanner widget for preview
- ✅ Comprehensive error handling

This implementation should work reliably on iOS 16+ devices with proper permissions granted.
