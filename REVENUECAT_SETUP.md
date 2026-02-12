# RevenueCat Setup Guide — Habit Tracker

This app uses **RevenueCat** for subscriptions and **RevenueCat UI** for paywalls. The code is already wired; you only need to configure the dashboard and store products.

---

## 1. Implementation Check (Already Done in Code)

- **SDK**: `purchases_flutter` + `purchases_ui_flutter` in `pubspec.yaml`
- **Init**: `PurchaseService.initialize()` runs at app startup (`main.dart` → `_initializeBackgroundServices`)
- **Entitlement ID**: `Habit Tracker Pro` — premium is gated by this entitlement
- **Paywall**: `RevenueCatUI.presentPaywall()` from Settings, Premium screen, Premium upgrade screen
- **Customer Center**: `RevenueCatUI.presentCustomerCenter()` for restore / manage subscription
- **Premium check**: `PurchaseService().isPremium` (used for hiding ads, etc.)
- **API keys**: In `lib/services/purchase_service.dart` — use **iOS** and **Android** public API keys from your RevenueCat project for production

---

## 2. RevenueCat Dashboard Steps

### Step 1: Create a project and apps

1. Go to [RevenueCat](https://app.revenuecat.com) and sign in.
2. **Project** → Create or select your project (e.g. "Habit Tracker").
3. Add two **apps**:
   - **iOS**: Bundle ID `com.LTS.habittracker` (must match Xcode).
   - **Android**: Package name from `android/app/build.gradle` (e.g. `com.lts.habittracker`).
4. For each app, connect the store:
   - **iOS**: App Store Connect (API key / Shared Secret or App Store Server API).
   - **Android**: Google Play (Service account JSON or linked billing).

### Step 2: Create the entitlement

1. In the dashboard go to **Product catalog** → **Entitlements**.
2. Click **+ New**.
3. Set **Identifier** to exactly: **`Habit Tracker Pro`**  
   (must match `entitlementId` in `purchase_service.dart`).
4. Save.

### Step 3: Create products in the store and attach in RevenueCat

1. **Apple App Store Connect** (iOS):
   - Create In-App Purchases (subscriptions or non-consumables) you want (e.g. monthly, yearly, lifetime).
   - Note the **Product IDs** (e.g. `remove_ads_monthly_ios`, `remove_ads_yearly_ios`).

2. **Google Play Console** (Android):
   - Create subscriptions or one-time products.
   - Note the **Product IDs**.

3. In RevenueCat: **Product catalog** → **Products**:
   - Add each product and link it to the correct store (App Store / Google Play) and Product ID.

4. **Attach products to the entitlement**:
   - Open the **Habit Tracker Pro** entitlement.
   - Use **Attach** to link each product (monthly, yearly, lifetime) to this entitlement.

### Step 4: Get API keys and put them in the app

1. In RevenueCat: **Project** → **API Keys**.
2. Copy:
   - **iOS** → Public API key (e.g. `appl_xxxx`).
   - **Android** → Public API key (e.g. `goog_xxxx`).
3. In the app open **`lib/services/purchase_service.dart`** and set:
   - `_revenueCatApiKeyIOS` = your iOS public key.
   - `_revenueCatApiKeyAndroid` = your Android public key.  
   (For testing you can keep using the test key until the project is fully set up.)

### Step 5: Paywalls (RevenueCat UI)

The app uses **RevenueCat’s default paywall** via `RevenueCatUI.presentPaywall()`. No extra in-app layout is required.

1. In RevenueCat go to **Paywalls** (or **Offerings** if you use the older flow).
2. Create a **Paywall**:
   - Choose a template or custom design.
   - Add **Packages** (e.g. Monthly, Annual, Lifetime) and map each package to the **products** you created and attached to **Habit Tracker Pro**.
3. Create an **Offering** (if your project uses offerings):
   - Add a **default** offering and attach the paywall you created.
   - The SDK will show this when you call `presentPaywall()`.

If you use **Offerings**:

- In **Product catalog** → **Offerings**, create an offering (e.g. "default").
- Attach the paywall and packages to that offering.
- The app will show the paywall that RevenueCat returns for the default offering.

### Step 6: Test

1. Use **Sandbox** (iOS) and **Test track** (Android) with test accounts.
2. In the app: open Premium or Settings → Remove Ads / Manage subscription.
3. Confirm:
   - Paywall appears.
   - Purchase and restore update `PurchaseService().isPremium` and hide ads.

---

## 3. Quick Checklist

- [ ] RevenueCat project created; iOS and Android apps added and store credentials connected.
- [ ] Entitlement **Habit Tracker Pro** created (identifier exactly as above).
- [ ] Products created in App Store Connect and Google Play; same products added and attached to **Habit Tracker Pro** in RevenueCat.
- [ ] Paywall (and optional default Offering) created in RevenueCat with packages linked to those products.
- [ ] iOS and Android public API keys copied into `purchase_service.dart`.
- [ ] Test purchase and restore; premium state and ad removal work as expected.

---

## 4. References

- [RevenueCat Quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)
- [Entitlements](https://www.revenuecat.com/docs/getting-started/entitlements)
- [Configuring products](https://www.revenuecat.com/docs/projects/configuring-products)
- [Displaying paywalls (RevenueCat UI)](https://www.revenuecat.com/docs/tools/paywalls-v2/displaying-paywalls)
