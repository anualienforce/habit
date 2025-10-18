import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Subscription IDs - These must match your Google Play Console setup
  static const String monthlySubscriptionId = 'premium_monthly_subscription';
  static const String yearlySubscriptionId = 'premium_yearly_subscription';
  static const String _premiumKey = 'is_premium_user';
  static const String _subscriptionEndDateKey = 'subscription_end_date';
  static const String _subscriptionTypeKey = 'subscription_type';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Available products
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isInitialized = false;

  // Getters
  bool get isPremium => _isPremium;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  List<ProductDetails> get products => _products;

  ProductDetails? get monthlySubscription =>
      _products.where((p) => p.id == monthlySubscriptionId).firstOrNull;

  ProductDetails? get yearlySubscription =>
      _products.where((p) => p.id == yearlySubscriptionId).firstOrNull;

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🛒 Initializing Purchase Service...');

      // Check if in-app purchase is available
      _isAvailable = await _inAppPurchase.isAvailable();
      print('🛒 IAP Available: $_isAvailable');

      if (!_isAvailable) {
        print('❌ In-App Purchase not available on this device');
        _isInitialized = true;
        return;
      }

      // Load premium status from local storage
      await _loadPremiumStatus();

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => print('🛒 Purchase stream closed'),
        onError: (error) => print('🛒 Purchase stream error: $error'),
      );

      // Load available products
      await _loadProducts();

      // Restore previous purchases
      await _restorePurchases();

      _isInitialized = true;
      print('✅ Purchase Service initialized successfully');

    } catch (e) {
      print('❌ Error initializing Purchase Service: $e');
      _isInitialized = true; // Still mark as initialized to prevent retry loops
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {monthlySubscriptionId, yearlySubscriptionId};
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        print('❌ Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      print('🛒 Loaded ${_products.length} products');

      for (final product in _products) {
        print('   - ${product.id}: ${product.title} (${product.price})');
      }

    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      print('🛒 Processing purchase: ${purchaseDetails.productID}');
      print('   Status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('⏳ Purchase pending...');
          break;

        case PurchaseStatus.purchased:
          print('✅ Purchase completed!');
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.restored:
          print('🔄 Purchase restored!');
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          print('❌ Purchase error: ${purchaseDetails.error}');
          _handleFailedPurchase(purchaseDetails);
          break;

        case PurchaseStatus.canceled:
          print('🚫 Purchase canceled by user');
          break;
      }

      // Complete the purchase (important for consumables)
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == monthlySubscriptionId) {
      await _setPremiumStatus(true);
      await _setSubscriptionType('monthly');
      await _setSubscriptionEndDate(DateTime.now().add(const Duration(days: 30)));
      print('🎉 User subscribed to monthly premium!');
    } else if (purchaseDetails.productID == yearlySubscriptionId) {
      await _setPremiumStatus(true);
      await _setSubscriptionType('yearly');
      await _setSubscriptionEndDate(DateTime.now().add(const Duration(days: 365)));
      print('🎉 User subscribed to yearly premium!');
    }
  }

  /// Handle failed purchase
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    // Log error for analytics/debugging
    print('💥 Purchase failed for ${purchaseDetails.productID}: ${purchaseDetails.error}');
  }

  /// Purchase premium subscription (monthly or yearly)
  Future<bool> purchaseSubscription({required bool isYearly}) async {
    try {
      if (!_isAvailable) {
        print('❌ In-App Purchase not available');
        return false;
      }

      final subscription = isYearly ? yearlySubscription : monthlySubscription;
      if (subscription == null) {
        print('❌ ${isYearly ? "Yearly" : "Monthly"} subscription not found');
        return false;
      }

      print('🛒 Initiating ${isYearly ? "yearly" : "monthly"} subscription...');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: subscription,
        applicationUserName: null, // Optional: user identifier
      );

      // Use buyNonConsumable for subscriptions (in_app_purchase plugin handles both)
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print('🛒 Subscription request sent: $success');
      return success;

    } catch (e) {
      print('❌ Error subscribing to premium: $e');
      return false;
    }
  }

  /// Purchase monthly subscription (backward compatibility)
  Future<bool> purchasePremium() async {
    return purchaseSubscription(isYearly: false);
  }

  /// Restore previous purchases
  Future<void> _restorePurchases() async {
    try {
      print('🔄 Restoring previous purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('❌ Error restoring purchases: $e');
    }
  }

  /// Manually restore purchases (for user-initiated restore)
  Future<bool> restorePurchases() async {
    try {
      print('🔄 User initiated purchase restore...');
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Load premium status from local storage
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      print('📱 Premium status loaded: $_isPremium');
    } catch (e) {
      print('❌ Error loading premium status: $e');
      _isPremium = false;
    }
  }

  /// Save premium status to local storage
  Future<void> _setPremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      _isPremium = isPremium;
      print('💾 Premium status saved: $_isPremium');
    } catch (e) {
      print('❌ Error saving premium status: $e');
    }
  }

  /// Set subscription end date
  Future<void> _setSubscriptionEndDate(DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionEndDateKey, endDate.toIso8601String());
      print('📅 Subscription end date saved: $endDate');
    } catch (e) {
      print('❌ Error saving subscription end date: $e');
    }
  }

  /// Set subscription type (monthly/yearly)
  Future<void> _setSubscriptionType(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionTypeKey, type);
      print('📅 Subscription type saved: $type');
    } catch (e) {
      print('❌ Error saving subscription type: $e');
    }
  }

  /// Get monthly subscription price
  String getMonthlyPrice() {
    final subscription = monthlySubscription;
    return subscription?.price ?? r'$1.99/month';
  }

  /// Get yearly subscription price
  String getYearlyPrice() {
    final subscription = yearlySubscription;
    return subscription?.price ?? r'$19/year';
  }

  /// Get subscription price (defaults to monthly for backward compatibility)
  String getPremiumPrice() {
    return getMonthlyPrice();
  }

  /// Get subscription title
  String getPremiumTitle() {
    return 'Premium Subscription';
  }

  /// Get subscription description
  String getPremiumDescription() {
    return 'Remove all advertisements and enjoy premium features';
  }

  /// Check if user has premium (public method for UI)
  Future<bool> checkPremiumStatus() async {
    await _loadPremiumStatus();
    return _isPremium;
  }

  /// For testing: simulate premium purchase (DEBUG ONLY)
  Future<void> debugSetPremium(bool isPremium) async {
    if (kDebugMode) {
      await _setPremiumStatus(isPremium);
      print('🧪 DEBUG: Premium status set to $isPremium');
    }
  }

  /// Dispose of resources
  void dispose() {
    _subscription.cancel();
  }

  /// Get purchase status info for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isAvailable': _isAvailable,
      'isPremium': _isPremium,
      'productsLoaded': _products.length,
      'monthlySubscriptionFound': monthlySubscription != null,
      'yearlySubscriptionFound': yearlySubscription != null,
      'premiumPrice': getPremiumPrice(),
    };
  }
}
