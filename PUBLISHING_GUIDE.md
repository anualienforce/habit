# Publishing Guide for Habit Tracker App

## Current App Information
- **App Name**: Habittracker
- **Package ID (Android)**: `com.LTS.habittracker`
- **Bundle ID (iOS)**: Check in Xcode project settings
- **Current Version**: 1.0.2+3
- **Min Android SDK**: 21
- **Min iOS**: 13.0

---

## 📱 iOS Publishing (App Store)

### Prerequisites
1. **Apple Developer Account** ($99/year)
   - Sign up at https://developer.apple.com
   - Enroll in Apple Developer Program

2. **App Store Connect Setup**
   - Go to https://appstoreconnect.apple.com
   - Create a new app with your bundle identifier
   - Fill in app information (name, description, screenshots, etc.)

### Step 1: Configure Bundle Identifier
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project → Runner target
3. Go to "Signing & Capabilities"
4. Set your Team and ensure Bundle Identifier matches App Store Connect
5. Enable "Automatically manage signing"

### Step 2: Update Version & Build Number
In `pubspec.yaml`:
```yaml
version: 1.0.3+4  # Increment version (major.minor.patch) and build number (+)
```

### Step 3: Build iOS App
```bash
# Clean build
flutter clean
flutter pub get

# Build for release
flutter build ipa --release
```

Or use Xcode:
1. Open `ios/Runner.xcworkspace`
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow the distribution wizard

### Step 4: Upload to App Store Connect
1. In Xcode Organizer, select your archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Select "Upload"
5. Follow the prompts to upload

### Step 5: Submit for Review
1. Go to App Store Connect
2. Select your app
3. Fill in all required information:
   - App description
   - Screenshots (required sizes):
     - iPhone 6.7" (1290 x 2796)
     - iPhone 6.5" (1242 x 2688)
     - iPhone 5.5" (1242 x 2208)
   - Privacy policy URL (required)
   - App category
   - Age rating
   - Pricing
4. Submit for review

### Step 6: Required App Store Assets
- **App Icon**: 1024x1024px (no transparency)
- **Screenshots**: Multiple sizes for different devices
- **App Preview Videos** (optional but recommended)
- **Privacy Policy URL**: Required for apps with ads/in-app purchases

### Step 7: Configure In-App Purchases (Required for Premium Features)

**⚠️ CRITICAL: Products must be configured in App Store Connect before TestFlight/App Store will work!**

1. **Go to App Store Connect**
   - Navigate to your app
   - Click on "Features" → "In-App Purchases"
   - Click the "+" button to create new products

2. **Create Subscription Products**
   
   **Monthly Subscription:**
   - Product Type: Auto-Renewable Subscription
   - Product ID: `remove_ads_monthly_ios` (must match exactly)
   - Reference Name: "Remove Ads Monthly"
   - Subscription Group: Create a new group (e.g., "Premium Subscriptions")
   - Subscription Duration: 1 Month
   - Price: Set your price (e.g., $2.99/month)
   - Localization: Add display name and description
   - Review Information: Provide screenshots and description
   - Click "Save" and submit for review

   **Yearly Subscription:**
   - Product Type: Auto-Renewable Subscription
   - Product ID: `remove_ads_yearly_ios` (must match exactly)
   - Reference Name: "Remove Ads Yearly"
   - Subscription Group: Same group as monthly
   - Subscription Duration: 1 Year
   - Price: Set your price (e.g., $19.99/year)
   - Localization: Add display name and description
   - Review Information: Provide screenshots and description
   - Click "Save" and submit for review

   **Lifetime Remove Ads (Optional):**
   - Product Type: Non-Consumable
   - Product ID: `remove_ads_lifetime_ios` (must match exactly)
   - Reference Name: "Remove Ads Lifetime"
   - Price: Set your price (e.g., $49.99)
   - Localization: Add display name and description
   - Review Information: Provide screenshots and description
   - Click "Save" and submit for review

3. **Important Notes:**
   - Product IDs must match exactly what's in `purchase_service.dart`
   - Products must be submitted for review and approved before they work
   - For TestFlight: Products must be in "Ready to Submit" or "Approved" status
   - Products are associated with your app's bundle ID automatically
   - Subscription groups allow users to switch between plans

4. **Testing In-App Purchases:**
   - **Sandbox Testing**: Create sandbox test accounts in App Store Connect
   - **TestFlight**: Use real Apple IDs (will use sandbox environment)
   - **Production**: Only works after app is approved and products are approved

5. **Troubleshooting StoreKit Issues:**
   - ✅ Verify product IDs match exactly (case-sensitive)
   - ✅ Ensure products are created and submitted in App Store Connect
   - ✅ Check that products are in "Ready to Submit" or "Approved" status
   - ✅ Verify bundle ID matches between app and App Store Connect
   - ✅ For TestFlight: Sign out of App Store, then sign in with test account
   - ✅ Check device logs for detailed error messages
   - ✅ Ensure app is properly signed with distribution certificate

6. **TestFlight IAP – “StoreKit failed to get response” fix checklist:**
   - **Xcode → Runner target → Signing & Capabilities:** Click **+ Capability** and add **In-App Purchase**. This ensures the App ID has IAP enabled for distribution/TestFlight.
   - **App Store Connect → Agreements, Tax, and Banking:** Complete the **Paid Applications** agreement and banking/tax info. IAP can be blocked until this is done.
   - **App Store Connect → Your app → In-App Purchases:** Ensure the three products exist with IDs `remove_ads_monthly_ios`, `remove_ads_yearly_ios`, `remove_ads_lifetime_ios` and are **Ready to Submit** or **Approved** (not Missing Metadata).
   - **Bundle ID:** Must match exactly (e.g. `com.LTS.habittracker`) in Xcode and App Store Connect.
   - After adding the **In-App Purchase** capability, create a **new archive** and upload a new build to TestFlight; old builds won’t get the updated provisioning.

7. **Why simulator works but TestFlight shows StoreKit failed to get response:**
   - **Simulator with StoreKit config file:** When you run from Xcode with a StoreKit configuration file (e.g. synced with App Store), the **simulator uses that local file** to answer product requests. No network call to Apple is made for product loading. So if the file is synced with your dev team or App Store, products appear and purchases work in the simulator.
   - **TestFlight:** The IPA you upload **does not include** the StoreKit config file. On TestFlight, the app **always** talks to **Apple servers** (Sandbox) to load products. So the same app is not the same at runtime: simulator uses a local file, TestFlight uses the network and App Store Connect.
   - So the issue is **not** that your products are missing (your StoreKit file proves they exist). On TestFlight, one of these is wrong:
     - **Provisioning:** The **distribution** profile used for the Archive was created **before** you added the **In-App Purchase** capability to the App ID, so the profile does not include IAP. Fix: Add **In-App Purchase** in Xcode (Signing and Capabilities), then create a **new** distribution profile in the Developer portal (or let Xcode regenerate it), then **re-archive and upload** a new build.
     - **Paid Applications agreement:** Not completed in App Store Connect (Agreements, Tax, and Banking).
     - **Product status:** Products exist but are Missing Metadata or Developer Action Needed – they must be Ready to Submit or Approved.
     - **Bundle ID:** Must match exactly between the app and App Store Connect.
   - **Summary:** Same code, same products – simulator uses a local StoreKit file; TestFlight uses the network and your **distribution provisioning profile** must have In-App Purchase enabled (add capability, then new profile and new build).

8. **When everything is verified but TestFlight IAP still fails:**
   - **Product IDs character-by-character:** In App Store Connect, open each IAP and confirm the Product ID is exactly: `remove_ads_monthly_ios`, `remove_ads_yearly_ios`, `remove_ads_lifetime_ios` (no space, correct underscores, lowercase). Any typo causes "no response".
   - **Subscription group:** Monthly and yearly must be in the **same** subscription group. If one is in a different group or missing, products may not load.
   - **In-App Purchases linked to app/version:** In App Store Connect, open your app, then the version used for TestFlight. Check if there is an **In-App Purchases** section where you must add/select the products for this version. If that step exists and is empty, add the three products.
   - **Territory/availability:** For each product, check **Availability** – the sandbox account country must be included. If the product is not available in the sandbox tester region, Sandbox can fail.
   - **Device logs:** Connect the iPhone (TestFlight build), open Xcode → Window → Devices and Simulators → select device → **Open Console**. Reproduce the purchase tap and look for StoreKit/SKError logs. The exact error code (e.g. SKErrorCode) can point to the cause.
   - **How to capture TestFlight console logs (for “StoreKit failed to get response”):**
     1. Install and open the app from **TestFlight** on your iPhone (do not run from Xcode).
     2. Connect the iPhone to your Mac with a cable.
     3. On Mac: **Xcode → Window → Devices and Simulators** → select your device → click **Open Console**.
     4. In the console, clear or start streaming. On the device, open your app and tap the action that triggers the purchase (e.g. Remove Ads).
     5. Copy or save the console output that appears when the error happens (look for lines containing `StoreKit`, `SKError`, `IAP`, or your app/bundle ID). Share these **iOS device console logs** (not Android Gradle output) for diagnosis.
   - **New sandbox tester:** Create a **new** Sandbox Tester (different email) in App Store Connect → Users and Access → Sandbox Testers. On device: Settings → App Store → sign out of sandbox, then in the app tap purchase and sign in with the **new** sandbox account. Rules out a bad account.
   - **Contact Apple Developer Support:** If provisioning, agreement, products, build, and sandbox are all correct, the issue can be server-side or account-specific. Contact [Apple Developer Support](https://developer.apple.com/contact/) with: app name, bundle ID, that IAP works in simulator with StoreKit config but fails on TestFlight with "StoreKit failed to get response", and that Paid Applications and profile IAP are set. They can check your account and Sandbox status.

9. **If device logs show "No active account" (ASDErrorDomain Code=509):**
   - Your `ios/error.txt`-style logs showed: `[LoadInAppReceiptsTask]: No active account for receipt request` and `Error syncing receipts for com.LTS.habittracker - Error Domain=ASDErrorDomain Code=509 "No active account"`. The product request to Apple’s sandbox can still **succeed** (e.g. StatusCode 200, "Decoded product response"), but StoreKit also runs **receipt/transaction sync**; when there is **no Sandbox Apple ID** signed in on the device, that sync fails with 509 and the app can surface a generic "StoreKit failed to get response".
   - **Fix:** On the **iPhone**: open **Settings → App Store** → scroll down to **Sandbox Account**. **Sign in** with a Sandbox Tester Apple ID (create one in App Store Connect → Users and Access → Sandbox Testers if needed). Do **not** use your real Apple ID here. After signing in with a sandbox account, try the in-app purchase again on the TestFlight build. You do **not** need to log into the TestFlight app with the sandbox account—use your normal Apple ID for TestFlight; only **Settings → App Store → Sandbox Account** is used by StoreKit when the app makes a purchase.
   - If logs also show `storefront = (null)` or "We can't update this account's storefront because the source account has no storefront", that confirms the device had no valid sandbox account for StoreKit; signing in a sandbox account fixes it.

10. **Sandbox account already added but logs still show 509 / "no storefront":**
   - If you already signed in under **Settings → App Store → Sandbox Account** and the logs still show "No active account" and "source account has no storefront", storekitd is not using that account. Try these in order:
   - **Important:** Do **not** sign in with the Sandbox Tester in **Media & Purchases**. Sandbox accounts are not full App Store accounts and have no storefront—using them as the main account can cause or worsen 509. **Media & Purchases** should be your **real** Apple ID. Use the sandbox account only in **Sandbox Account** (bottom of App Store settings) or when the **purchase sheet in the app** asks for an Apple ID.
   - **A. Force in-app sign-in (try this first):** On the device: **Settings → App Store → Sandbox Account** → tap **Sign Out**. Put your **real** Apple ID back in **Media & Purchases** if you had signed out. Then open your **TestFlight** app, tap the purchase (e.g. Remove Ads) so the **purchase sheet** appears. When iOS asks for an Apple ID, sign in with your **Sandbox Tester** email/password **there**. That activates the sandbox account for that app. After that, try loading plans or purchasing again.
   - **B. Restart the device** after any account change, then try the purchase again.
   - **C. New Sandbox Tester:** In App Store Connect → Users and Access → Sandbox Testers, create a **new** sandbox account (new email, set country/region). On device: Settings → App Store → Sandbox Account → Sign Out. In the app, trigger the purchase and when the sheet appears sign in with the **new** sandbox account. Old sandbox accounts can be in a "no storefront" state.
   - **D. Region:** In App Store Connect, open the Sandbox Tester and ensure **country/region** is set. In your app’s IAP, ensure products are **available** in that territory. No valid storefront for that region causes "no storefront".

11. **Purchase sheet never appears (only a snackbar / error):**
   - When products fail to load with 509, the app never gets product details, so it never calls "buy" and the native purchase sheet never shows. The app now handles this: (1) In the Remove Ads modal, if plans didn't load (sandbox sign-in needed), a banner tells you to tap **Restore Purchases** first. (2) When you tap Monthly/Yearly/Lifetime and products are empty, a dialog appears: **Sandbox sign-in required** — tap **Restore Purchases** there (or in the modal). When iOS asks for your Apple ID, sign in with your Sandbox Tester account. Then close the dialog/modal and try again; after sign-in, plans may load and the purchase sheet can appear.

12. **Unable to Install on device from Xcode (“Beta profile” / 0xe800801f):**
   - Error: *"Failed to install embedded profile for com.LTS.habittracker : 0xe800801f (Attempted to install a Beta profile without the proper entitlement.)"* or *"This app cannot be installed because its integrity could not be verified."*
   - **Cause:** You are **running** (▶ Run) from Xcode to a physical device, but the build is signed with a **Distribution** (App Store/TestFlight) provisioning profile. Direct install to a device from Xcode expects a **Development** profile.
   - **Fix:** In Xcode, select the **Runner** target → **Signing & Capabilities**. For **Run** to device (Debug/Profile), use **Development** signing:
     - **Debug** and **Profile** configurations: Team = your team, **Signing Certificate** = **Apple Development** (not Apple Distribution). Enable **Automatically manage signing** so Xcode creates/uses a **Development** provisioning profile for `com.LTS.habittracker`.
     - **Release** (used for **Product → Archive**): Can stay as **Apple Distribution** for TestFlight/App Store.
   - So: **Run to device** = Development profile; **Archive → Distribute** = Distribution profile. After switching to Development for Debug, clean (Product → Clean Build Folder) and run again to the device.

13. **IAP not working after app is live on App Store:**
   - **Production** IAP only works when: (1) The app is **approved** and live, (2) In-App Purchase products are **approved** (not just “Ready to Submit”), (3) User is signed in with a **real** Apple ID (no Sandbox Account on device for production), (4) **Paid Applications** agreement is complete, (5) Bundle ID and product IDs match exactly.
   - If purchase flow fails in production: Check App Store Connect → Your app → In-App Purchases: ensure all three products show **Approved**. Ensure the app version in the store has IAP products linked. Users must have a valid payment method and region where the products are available. If it still fails, capture device logs (Xcode → Window → Devices and Simulators → Console) while reproducing the purchase and look for StoreKit/SKError messages.

14. **IAP works when Run from Xcode to device but NOT when downloaded from App Store:**
   - **Cause:** The app you run from Xcode uses a **Development** provisioning profile (with In-App Purchase capability). The **live build** on the App Store was built with a **Distribution** profile. If that Distribution profile was created **before** you added the **In-App Purchase** capability to the App ID, the embedded profile in the App Store build **does not include IAP** — so StoreKit/product loading or purchase can fail in production even though the same code works when run from Xcode.
   - **Fix (requires a new build):**
     1. In Xcode: open **Runner** target → **Signing & Capabilities** → click **+ Capability** → add **In-App Purchase**. This updates your App ID in the developer portal to include IAP.
     2. Create a **new** Distribution provisioning profile (in developer.apple.com → Certificates, Identifiers & Profiles → Profiles, edit the App Store profile for `com.LTS.habittracker` and regenerate, or let Xcode create a new one when you archive).
     3. **Product → Clean Build Folder**, then **Product → Archive**.
     4. **Distribute App** → App Store Connect → Upload. Submit this new build as a new version (e.g. 1.0.63+7).
   - The **current live build on the App Store cannot be fixed** without shipping a new version; the embedded profile in the existing IPA does not have IAP. After uploading a build that was archived **after** adding the In-App Purchase capability, production IAP should work.
   - **Why Run from Xcode works:** Development profile already had IAP (or you added the capability and Xcode uses it for Run). The StoreKit configuration file (`storekit.storekit`) in the project is used for local/simulator testing when run from Xcode; it is **not** used when the app is downloaded from the App Store — production uses Apple's servers. The real issue is the Distribution profile used for the live build.

---

## 🤖 Android Publishing (Google Play Store)

### Prerequisites
1. **Google Play Developer Account** ($25 one-time fee)
   - Sign up at https://play.google.com/console
   - Pay the registration fee

2. **Keystore File**
   - Your app already has `android/key.properties` configured
   - Ensure `android/release-key.keystore` exists
   - If missing, create it:
     ```bash
     cd android
     keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
     ```

### Step 1: Update Version
In `pubspec.yaml`:
```yaml
version: 1.0.3+4  # Increment version and build number
```

### Step 2: Build Android App Bundle (AAB)
```bash
# Clean build
flutter clean
flutter pub get

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

The output will be at: `build/app/outputs/bundle/release/app-release.aab`

### Step 3: Create App in Google Play Console
1. Go to https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - App name: Habittracker
   - Default language: English
   - App or game: App
   - Free or paid: Choose your option
   - Declarations: Accept policies

### Step 4: Upload AAB to Play Console
1. Go to "Production" (or "Internal testing" for testing)
2. Click "Create new release"
3. Upload your `app-release.aab` file
4. Add release notes
5. Review and roll out

### Step 5: Complete Store Listing
Fill in required information:
- **App name**: Habittracker
- **Short description**: (80 characters max)
- **Full description**: (4000 characters max)
- **App icon**: 512x512px PNG (no transparency)
- **Feature graphic**: 1024x500px
- **Screenshots**: 
  - Phone: At least 2, max 8 (16:9 or 9:16)
  - Tablet: Optional but recommended
- **Privacy Policy URL**: Required (especially with ads/IAP)
- **Content rating**: Complete questionnaire
- **Target audience**: Set age groups

### Step 6: Required Assets
- **App Icon**: 512x512px PNG
- **Feature Graphic**: 1024x500px
- **Phone Screenshots**: Minimum 2, recommended 4-8
- **Privacy Policy**: Required for apps with:
  - Ads (Google Mobile Ads)
  - In-app purchases
  - User data collection

---

## 🔐 Security Checklist

### Before Publishing

#### iOS
- [ ] Remove debug keys and test certificates
- [ ] Verify bundle identifier matches App Store Connect
- [ ] Test on physical device
- [ ] Verify all permissions are properly declared in Info.plist
- [ ] Check privacy policy URL is accessible
- [ ] Ensure app icon is 1024x1024px

#### Android
- [ ] Verify keystore file is secure and backed up
- [ ] Test release build on physical device
- [ ] Verify all permissions in AndroidManifest.xml
- [ ] Check ProGuard rules (if enabled)
- [ ] Ensure app icon is 512x512px
- [ ] Verify Google Mobile Ads App ID is correct

---

## 📝 Version Management

### Version Number Format
`version: X.Y.Z+BUILD`
- **X.Y.Z**: Version name (shown to users)
- **BUILD**: Build number (must increment each release)

### Example Versioning
```
1.0.0+1  → First release
1.0.1+2  → Bug fix
1.1.0+3  → New features
2.0.0+4  → Major update
```

### Update Version Before Each Release
1. Edit `pubspec.yaml`
2. Increment version and build number
3. Run `flutter pub get`
4. Rebuild app

---

## 🧪 Testing Before Publishing

### iOS Testing
```bash
# Build and test on device
flutter build ios --release
# Install via Xcode or TestFlight
```

### Android Testing
```bash
# Build APK for testing
flutter build apk --release

# Or build AAB for internal testing
flutter build appbundle --release
```

### TestFlight (iOS) / Internal Testing (Android)
- **iOS**: Upload to TestFlight for beta testing
- **Android**: Use Internal Testing track in Play Console

---

## 📋 Pre-Launch Checklist

### Both Platforms
- [ ] App tested on multiple devices
- [ ] All features working correctly
- [ ] No crashes or critical bugs
- [ ] Privacy policy published and accessible
- [ ] App description and screenshots ready
- [ ] Support email configured
- [ ] Terms of service (if applicable)
- [ ] Age rating completed
- [ ] Content rating appropriate

### iOS Specific
- [ ] App Store Connect listing complete
- [ ] Screenshots for all required device sizes
- [ ] App icon 1024x1024px
- [ ] Bundle ID matches App Store Connect
- [ ] TestFlight testing completed
- [ ] In-app purchase products created in App Store Connect
- [ ] Product IDs match exactly (case-sensitive)
- [ ] In-app purchases tested in TestFlight
- [ ] Products submitted for review and approved

### Android Specific
- [ ] Play Console listing complete
- [ ] Screenshots uploaded
- [ ] App icon 512x512px
- [ ] Feature graphic 1024x500px
- [ ] Keystore file backed up securely
- [ ] Content rating questionnaire completed

---

## 🚀 Quick Commands Reference

### Build Commands
```bash
# iOS
flutter build ipa --release

# Android APK
flutter build apk --release

# Android App Bundle (recommended)
flutter build appbundle --release
```

### Version Update
```bash
# Edit pubspec.yaml, then:
flutter pub get
```

### Clean Build
```bash
flutter clean
flutter pub get
```

---

## 📞 Support Resources

- **Flutter Documentation**: https://flutter.dev/docs/deployment
- **iOS App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Google Play Policies**: https://play.google.com/about/developer-content-policy/
- **App Store Connect**: https://appstoreconnect.apple.com
- **Google Play Console**: https://play.google.com/console

---

## ⚠️ Important Notes

1. **Keystore Backup**: Keep your Android keystore file safe! If lost, you cannot update your app.
2. **Bundle ID**: Cannot be changed after first release on iOS
3. **Package Name**: Cannot be changed after first release on Android
4. **Privacy Policy**: Required for apps with ads, IAP, or data collection
5. **Review Time**: 
   - iOS: Usually 24-48 hours
   - Android: Usually 1-3 days (can be longer for first submission)

---

## 🎯 Next Steps

1. **Update version** in `pubspec.yaml`
2. **Build release** versions for both platforms
3. **Create store listings** with screenshots and descriptions
4. **Submit for review**
5. **Monitor** for approval and respond to any feedback

Good luck with your app launch! 🚀
