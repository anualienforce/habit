# Apple In-App Purchase Setup

The app uses **only Apple in-app purchase** (StoreKit via Flutter’s `in_app_purchase` package). There is no RevenueCat.

## Product IDs

These are configured in **App Store Connect** and in `lib/services/purchase_service.dart`:

| Product ID                   | Type           | Description        |
|-----------------------------|----------------|--------------------|
| `remove_ads_monthly_ios`    | Subscription   | 1 month recurring  |
| `remove_ads_yearly_ios`    | Subscription   | 1 year recurring  |
| `remove_ads_lifetime_ios`  | Non-consumable | One-time remove ads |

They must match exactly (including spelling) for the app to load prices and complete purchases.

## Requirements

- **App Store Connect**: Create the products and attach them to your app. For subscriptions, create a subscription group and add monthly/yearly products.
- **Agreements & banking**: Complete the Paid Applications agreement and tax/banking in App Store Connect so IAP is active.
- **Testing**: Use a Sandbox Apple ID (App Store Connect → Users and Access → Sandbox) to test purchases on device/simulator.

## Flow

- **Premium screen** and **Premium upgrade screen** show the three plans with prices from the store and “Buy” buttons.
- **Restore purchases** calls StoreKit restore; premium status is updated when the purchase stream receives restored items.
- Premium state is persisted locally and used to hide ads (e.g. `PurchaseService().isPremium`).
