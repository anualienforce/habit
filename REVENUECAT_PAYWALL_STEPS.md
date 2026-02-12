# Add In-App Purchases to Your Habit Tracker Paywall (Step-by-Step)

Your app already shows RevenueCat’s paywall with `RevenueCatUI.presentPaywall()`. Follow these steps in the RevenueCat dashboard so products and the paywall work end-to-end.

---

## Step 1: Add your apps and connect the stores

1. In the **left sidebar**, click **Apps & providers**.
2. Click **+ New** (or **Add app**) and add:
   - **iOS app**
     - Name: e.g. "Habit Tracker iOS"
     - **Bundle ID**: `com.LTS.habittracker` (must match your Xcode project).
   - **Android app**
     - Name: e.g. "Habit Tracker Android"
     - **Package name**: from your `android/app/build.gradle` (e.g. `com.lts.habittracker`).
3. For each app, **connect the store**:
   - **iOS**: Link **App Store Connect** (API key or App Store Server API / Shared Secret).
   - **Android**: Link **Google Play** (service account or in-app products API).

Until the apps are added and stores connected, RevenueCat can’t see your real products.

---

## Step 2: Create products in the stores (if not done)

Create the actual in-app products in Apple and Google; then RevenueCat will use them.

**Apple (App Store Connect):**
1. App Store Connect → Your app → **In-App Purchases** (or **Subscriptions**).
2. Create the products you want, e.g.:
   - Subscription: monthly (e.g. `remove_ads_monthly_ios`).
   - Subscription: yearly (e.g. `remove_ads_yearly_ios`).
   - Non-consumable: lifetime (e.g. `remove_ads_lifetime_ios`).
3. Note the **exact Product IDs**; you’ll enter them in RevenueCat.

**Google (Play Console):**
1. Play Console → Your app → **Monetize** → **Products** → **Subscriptions** or **In-app products**.
2. Create matching products (e.g. same names/IDs as above).
3. Note the **exact Product IDs**.

---

## Step 3: Create the entitlement in RevenueCat

Your app checks the entitlement **`Habit Tracker Pro`**. Create it with that exact ID.

1. In the **left sidebar**, click **Product catalog**.
2. Open the **Entitlements** tab.
3. Click **+ New** (or **New entitlement**).
4. **Identifier**: type exactly **`Habit Tracker Pro`** (spaces and capitals as shown).
5. Save.

---

## Step 4: Add products in RevenueCat and attach to the entitlement

1. Still under **Product catalog**, open the **Products** tab.
2. For each product you created in App Store Connect / Play Console:
   - Click **+ New** (or **Add product**).
   - Choose **App Store** or **Google Play**.
   - **Product ID**: paste the exact ID from the store (e.g. `remove_ads_monthly_ios`).
   - Optionally set a display name.
   - Save.
3. **Attach products to the entitlement:**
   - Go back to **Entitlements**.
   - Open **Habit Tracker Pro**.
   - Use **Attach** (or **Link product**) and select each product (monthly, yearly, lifetime).
   - Save.

After this, any purchase of those products will grant the **Habit Tracker Pro** entitlement, and `PurchaseService().isPremium` in the app will be `true`.

---

## Step 5: Create a paywall and attach packages

So that `RevenueCatUI.presentPaywall()` shows your products:

1. In the **left sidebar**, click **Paywalls**.
2. Click **+ New** (or **New paywall**).
3. **Name**: e.g. "Default" or "Premium".
4. **Design**: pick a template or build a custom paywall; add titles, copy, and CTA buttons as you like.
5. **Packages** (this is what ties the paywall to in-app purchase):
   - Add a package (e.g. "Monthly") and select the **product** you created for monthly.
   - Add "Annual" / "Yearly" and select the yearly product.
   - Add "Lifetime" (if you have one) and select the lifetime product.
6. Save the paywall.

If your project uses **Offerings**:
- Go to **Product catalog** → **Offerings** (if available).
- Create or edit the **default** offering.
- Attach the paywall you just created to that offering.
- The SDK will show this when you call `presentPaywall()` with the default offering.

---

## Step 6: Get API keys and put them in the app

1. In the **left sidebar**, click **API keys**.
2. You’ll see **Public API keys** per app (e.g. iOS, Android).
3. Copy:
   - **iOS** public key (often starts with `appl_`).
   - **Android** public key (often starts with `goog_`).
4. In your project open **`lib/services/purchase_service.dart`**.
5. Replace the placeholders:
   - `_revenueCatApiKeyIOS` = your **iOS** public key.
   - `_revenueCatApiKeyAndroid` = your **Android** public key.

Save the file and rebuild the app.

---

## Step 7: Test in the app

1. **iOS**: Use a **Sandbox** tester account (App Store Connect → Users and Access → Sandbox Testers).  
   **Android**: Use a test account on a **testing track** (e.g. internal testing).
2. Run the app (simulator or device).
3. Open the paywall:
   - **Settings** → Remove Ads / Manage subscription, or  
   - **Premium** (or upgrade) screen.
4. Confirm:
   - The paywall appears with your packages (Monthly, Yearly, etc.).
   - A test purchase completes and the app shows “Pro” or removes ads.
   - **Restore** or **Customer Center** restores the purchase and premium state updates.

---

## Quick checklist

- [ ] **Apps & providers**: iOS and Android apps added; App Store and Google Play connected.
- [ ] **Stores**: Products created in App Store Connect and Google Play; Product IDs noted.
- [ ] **Product catalog → Entitlements**: Entitlement **`Habit Tracker Pro`** created.
- [ ] **Product catalog → Products**: All products added and **attached** to **Habit Tracker Pro**.
- [ ] **Paywalls**: One paywall created with **packages** linked to those products (and attached to default offering if you use Offerings).
- [ ] **API keys**: iOS and Android keys copied into `purchase_service.dart`.
- [ ] **Test**: Paywall shows, purchase and restore work, premium state and ad removal work in the app.

The “Integrations” page you were on is for webhooks and exports; the flow above uses **Product catalog**, **Paywalls**, and **API keys** to get in-app purchases working with your current paywall.
