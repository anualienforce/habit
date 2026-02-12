# TestFlight Upload Guide

## Quick Steps to Upload to TestFlight

### Step 1: Open the Correct Workspace
**IMPORTANT**: Always open `Runner.xcworkspace`, NOT `Runner.xcodeproj`

```bash
# From terminal
open ios/Runner.xcworkspace

# Or navigate to: ios/Runner.xcworkspace and double-click
```

### Step 2: Update Version Number (if needed)
Edit `pubspec.yaml`:
```yaml
version: 1.0.3+4  # Increment build number (+4) for new TestFlight build
```

Then run:
```bash
flutter pub get
```

### Step 3: Verify Build Settings in Xcode

1. **Select the Runner project** (blue icon at top of left sidebar)
2. **Select the Runner target** (under TARGETS, not PROJECTS)
3. **Go to "Signing & Capabilities" tab**
4. Ensure:
   - ✅ Team is selected
   - ✅ "Automatically manage signing" is checked
   - ✅ Bundle Identifier matches your App Store Connect app

### Step 4: Select Correct Scheme

1. At the top toolbar, click the scheme dropdown (next to the play/stop buttons)
2. Select **"Runner"** (not RunnerTests)
3. Select **"Any iOS Device"** or your connected device (NOT a simulator)

### Step 5: Clean Build Folder
In Xcode:
- **Product → Clean Build Folder** (Shift + Cmd + K)

Or from terminal:
```bash
flutter clean
flutter pub get
cd ios
pod install
```

### Step 6: Create Archive

**Option A: Using Xcode (Recommended)**
1. In Xcode, select **Product → Archive**
2. Wait for archive to complete (may take a few minutes)
3. The Organizer window will open automatically

**Option B: Using Flutter Command**
```bash
flutter build ipa --release
```
Then open Xcode → Window → Organizer to find the archive

### Step 7: Upload to TestFlight

1. In Xcode Organizer, select your archive
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Next"**
5. Select **"Upload"**
6. Click **"Next"**
7. Select your distribution options:
   - ✅ Upload your app's symbols (recommended)
   - ✅ Manage Version and Build Number (optional)
8. Click **"Next"**
9. Review and click **"Upload"**
10. Wait for upload to complete

### Step 8: Process in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Navigate to your app → **TestFlight** tab
3. Wait for processing (usually 5-15 minutes)
4. Once processed, you can:
   - Add testers
   - Add build notes
   - Submit for beta review (if needed)

---

## Troubleshooting: Build Settings Not Showing

### Issue: Can't see build settings in Xcode

**Solution 1: Open Workspace, Not Project**
- ❌ Wrong: `Runner.xcodeproj`
- ✅ Correct: `Runner.xcworkspace`

**Solution 2: Select Correct Target**
1. Click the **blue project icon** at top of left sidebar
2. Under **TARGETS**, click **"Runner"** (not PROJECTS)
3. Build settings will appear in the main area

**Solution 3: Show Build Settings**
1. In Xcode, go to **View → Navigators → Show Project Navigator** (Cmd + 1)
2. Click the project icon
3. Select Runner target
4. Click **"Build Settings"** tab (not "General")
5. If settings are collapsed, click the search box or use the filter

**Solution 4: Check Scheme**
- Make sure scheme is set to **"Runner"** (not RunnerTests)
- Device should be **"Any iOS Device"** or a physical device

---

## Common Issues

### Issue: "No signing certificate found"
**Fix**: 
1. Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download certificates
4. In project settings, select your team

### Issue: "Archive failed" or build errors
**Fix**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Issue: "Invalid Bundle" or code signing errors
**Fix**:
1. Xcode → Runner target → Signing & Capabilities
2. Uncheck "Automatically manage signing"
3. Check it again
4. Select your team
5. Let Xcode fix provisioning profiles

### Issue: Upload fails with "Invalid Bundle Identifier"
**Fix**:
- Ensure Bundle ID in Xcode matches App Store Connect exactly
- Check: Runner target → General → Bundle Identifier

---

## Quick Command Reference

```bash
# Clean everything
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build for TestFlight
flutter build ipa --release

# Or use Xcode Archive (Product → Archive)
```

---

## Version Number Format

- **Version**: `1.0.2` (shown to users)
- **Build**: `3` (must increment for each upload)

Each TestFlight upload needs a **unique build number** that's higher than the previous one.

---

## After Upload

1. **Wait for processing** (5-15 minutes)
2. **Check App Store Connect** → TestFlight tab
3. **Add testers** if needed
4. **Add build notes** describing what's new
5. **Submit for beta review** (if this is your first TestFlight build)

---

## Need Help?

- **Xcode Organizer**: Window → Organizer (Cmd + Shift + O)
- **App Store Connect**: https://appstoreconnect.apple.com
- **TestFlight Documentation**: https://developer.apple.com/testflight/

Good luck! 🚀
