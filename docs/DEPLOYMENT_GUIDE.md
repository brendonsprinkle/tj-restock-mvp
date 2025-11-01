# Deployment Guide

This guide provides step-by-step instructions for deploying the TJ Restock MVP app to iOS devices using free Apple Developer provisioning.

## Prerequisites

Before you begin, ensure you have:

- ✅ macOS computer with Xcode 14+ installed
- ✅ Flutter SDK 3.35.7 or later installed
- ✅ iPhone running iOS 16+ 
- ✅ Apple ID (free account is sufficient)
- ✅ USB cable to connect iPhone to Mac
- ✅ Project source code downloaded

## Step-by-Step Deployment

### Step 1: Prepare Your Mac

1. **Install Xcode** (if not already installed):
   - Open App Store
   - Search for "Xcode"
   - Click "Get" or "Install"
   - Wait for installation (this can take 30+ minutes)

2. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **Install Flutter** (if not already installed):
   ```bash
   # Clone Flutter repository
   git clone https://github.com/flutter/flutter.git -b stable
   
   # Add Flutter to PATH (add to ~/.zshrc or ~/.bash_profile)
   export PATH="$PATH:$HOME/flutter/bin"
   
   # Reload shell configuration
   source ~/.zshrc  # or source ~/.bash_profile
   
   # Verify installation
   flutter doctor
   ```

### Step 2: Prepare Your iPhone

1. **Enable Developer Mode**:
   - Open **Settings** on your iPhone
   - Go to **Privacy & Security**
   - Scroll down to **Developer Mode**
   - Toggle it **ON**
   - Restart your iPhone when prompted
   - After restart, confirm you want to enable Developer Mode

2. **Connect to Mac**:
   - Connect iPhone to Mac using USB cable
   - Unlock your iPhone
   - Tap **Trust** when prompted "Trust This Computer?"
   - Enter your iPhone passcode if requested

### Step 3: Configure the Project

1. **Navigate to project directory**:
   ```bash
   cd tj_restock_mvp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Open iOS project in Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

### Step 4: Configure Signing in Xcode

This is the most critical step for deployment.

1. **Select Runner in Project Navigator**:
   - In the left sidebar, click on "Runner" (the blue icon at the top)

2. **Go to Signing & Capabilities**:
   - Click the "Signing & Capabilities" tab at the top

3. **Configure Team**:
   - Uncheck "Automatically manage signing" (if checked)
   - Check "Automatically manage signing" again
   - In the "Team" dropdown, select your Apple ID
   - If you don't see your Apple ID:
     - Click "Add Account..."
     - Sign in with your Apple ID
     - Select your account from the dropdown

4. **Set Bundle Identifier**:
   - Change the Bundle Identifier to something unique
   - Format: `com.yourname.tjrestock`
   - Example: `com.taylor.tjrestock`
   - Must be globally unique (no one else can use the same ID)

5. **Verify Signing**:
   - You should see "iPhone Developer" under "Signing Certificate"
   - Status should show "Ready to Run" or similar
   - If you see errors, try:
     - Changing the Bundle Identifier
     - Logging out and back into your Apple ID in Xcode
     - Restarting Xcode

### Step 5: Build and Deploy

#### Option A: Deploy via Xcode (Recommended)

1. **Select your iPhone as target**:
   - At the top of Xcode, click the device dropdown
   - Select your iPhone from the list
   - It should show your iPhone's name

2. **Build and Run**:
   - Click the Play button (▶) in the top left
   - Or press `Cmd + R`
   - Wait for build to complete (first build takes 5-10 minutes)

3. **Watch for errors**:
   - If build fails, check the error messages
   - Common issues:
     - Bundle ID conflict: Change to a different Bundle ID
     - Signing error: Verify your Apple ID is logged in
     - Device not trusted: Check iPhone trust settings

#### Option B: Deploy via Flutter CLI

1. **List available devices**:
   ```bash
   flutter devices
   ```
   
   You should see your iPhone listed with a device ID.

2. **Run the app**:
   ```bash
   flutter run -d <device-id>
   ```
   
   Replace `<device-id>` with your iPhone's ID from the previous command.

### Step 6: Trust the App on iPhone

When you first run the app, you'll need to trust the developer certificate:

1. **Launch will fail initially** - this is expected
2. On your iPhone, go to **Settings**
3. Go to **General**
4. Scroll down to **VPN & Device Management**
5. Under "Developer App", find your Apple ID
6. Tap on it
7. Tap **Trust "[Your Apple ID]"**
8. Tap **Trust** again to confirm
9. Return to home screen and launch the app again

### Step 7: Grant Camera Permission

When you first open the scanner:

1. App will prompt for camera access
2. Tap **Allow** or **OK**
3. Camera preview should appear immediately
4. If you accidentally denied permission:
   - Go to **Settings → TJ Restock MVP**
   - Toggle Camera permission ON

## Troubleshooting Deployment Issues

### "Failed to register bundle identifier"

**Cause**: Bundle ID is already in use by another developer.

**Solution**:
1. In Xcode, change the Bundle Identifier
2. Try variations like:
   - `com.yourname.tjrestock2`
   - `com.yourname.tj-restock`
   - `com.yourfullname.tjrestock`

### "No signing certificate found"

**Cause**: Apple ID not properly configured in Xcode.

**Solution**:
1. Go to **Xcode → Preferences → Accounts**
2. Click the "+" button to add your Apple ID
3. Sign in
4. Select your account and click "Download Manual Profiles"
5. Return to Signing & Capabilities and select your team

### "Device not found"

**Cause**: iPhone not properly connected or trusted.

**Solution**:
1. Unplug and replug USB cable
2. Unlock iPhone
3. Tap "Trust" if prompted
4. In Xcode, go to **Window → Devices and Simulators**
5. Verify your iPhone appears in the list
6. If it shows a yellow dot, wait for it to turn green

### "Build failed with exit code 65"

**Cause**: Various build configuration issues.

**Solution**:
1. Clean build folder: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Close Xcode
3. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen Xcode and try again

### "The application could not be verified"

**Cause**: Developer certificate not trusted on device.

**Solution**:
1. Follow Step 6 above to trust the certificate
2. Make sure you completed the trust process fully
3. Restart the iPhone if needed

## Free Provisioning Limitations

### 7-Day Expiration

Apps installed with free provisioning expire after 7 days.

**What happens**:
- App icon remains on home screen
- Tapping it shows "Unable to Verify App"
- All data is preserved

**How to fix**:
1. Connect iPhone to Mac
2. Run the deployment process again (Steps 5-6)
3. App will work for another 7 days
4. Your data will still be there

**Pro tip**: Set a weekly reminder to rebuild the app.

### 3-App Limit

Free Apple IDs can only have 3 apps installed simultaneously.

**If you hit the limit**:
1. Delete an old app you're not using
2. Or upgrade to Apple Developer Program ($99/year)

### No Push Notifications

Free provisioning doesn't support:
- Push notifications
- In-app purchases
- Certain background modes

**For this app**: Not an issue, as we don't use these features.

## Upgrading to Paid Developer Account

If you want to avoid 7-day rebuilds:

1. **Join Apple Developer Program**:
   - Visit https://developer.apple.com/programs/
   - Enroll for $99/year
   - Wait for approval (1-2 days)

2. **Update Xcode**:
   - In Signing & Capabilities
   - Select your paid team
   - Apps will be valid for 1 year

3. **Optional: TestFlight**:
   - Upload builds to App Store Connect
   - Distribute via TestFlight
   - No USB cable needed for updates

## Deployment Checklist

Before deploying to production use:

- [ ] Camera permissions configured in Info.plist
- [ ] Unique Bundle Identifier set
- [ ] Apple ID configured in Xcode
- [ ] iPhone Developer Mode enabled
- [ ] Device trusted on Mac
- [ ] App builds without errors
- [ ] Camera preview works (not black screen)
- [ ] Barcode scanning works
- [ ] Manual entry works
- [ ] CSV export works
- [ ] All 19 sections present
- [ ] Haptic feedback works
- [ ] Offline functionality works

## Deployment to Multiple Devices

To deploy to additional iPhones:

1. **Same Apple ID**:
   - Connect new iPhone
   - Follow Steps 2, 5, and 6
   - No Xcode configuration changes needed

2. **Different Apple ID**:
   - Each person needs to build with their own Apple ID
   - Each person needs their own unique Bundle ID
   - Share the source code
   - Each person follows full deployment process

## Maintenance Schedule

### Weekly (Free Provisioning)
- Rebuild app before 7-day expiration
- Check for Flutter/package updates

### Monthly
- Review and update dependencies
- Check for iOS updates
- Test on latest iOS version

### As Needed
- Update sections list if store layout changes
- Add new features based on feedback
- Fix bugs reported by users

## Getting Help

If you encounter issues not covered here:

1. Check the [Camera Troubleshooting Guide](CAMERA_TROUBLESHOOTING.md)
2. Review the [main README](../README.md)
3. Check Flutter documentation: https://docs.flutter.dev
4. Check mobile_scanner documentation: https://pub.dev/packages/mobile_scanner

## Summary

Deployment process:
1. ✅ Prepare Mac with Xcode and Flutter
2. ✅ Prepare iPhone with Developer Mode
3. ✅ Configure project and install dependencies
4. ✅ Set up signing in Xcode with unique Bundle ID
5. ✅ Build and deploy to iPhone
6. ✅ Trust certificate on device
7. ✅ Grant camera permission
8. ✅ Rebuild weekly (free provisioning)

With proper setup, deployment takes 5-10 minutes after the first time.
