import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apple (and Android) in-app purchase service — no RevenueCat.
/// Premium is unlocked by any of: monthly subscription, yearly subscription, or lifetime purchase.
/// Product IDs must match App Store Connect (iOS) and Google Play Console (Android).
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  /// Product IDs — must match App Store Connect (iOS) exactly.
  static const String monthlyProductId = 'remove_ads_monthly_ios';
  static const String yearlyProductId = 'remove_ads_yearly_ios';
  static const String lifetimeProductId = 'remove_ads_lifetime_ios';

  static const Set<String> _productIds = {
    monthlyProductId,
    yearlyProductId,
    lifetimeProductId,
  };

  static const String _premiumKey = 'habit_tracker_premium';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _premiumFromPrefs = false;
  // Diagnostic state for "Loading plans..." (e.g. on TestFlight)
  bool _lastIsAvailable = false;
  List<String> _lastNotFoundIds = [];
  String? _lastProductError;

  bool get isInitialized => _isInitialized;
  bool get lastIsAvailable => _lastIsAvailable;
  List<String> get lastNotFoundIds => List.unmodifiable(_lastNotFoundIds);
  String? get lastProductError => _lastProductError;
  String get productLoadDiagnostic {
    if (!_lastIsAvailable) return 'Store not available';
    if (_lastProductError != null) return 'Error: $_lastProductError';
    if (_lastNotFoundIds.isNotEmpty) return 'Products not found: ${_lastNotFoundIds.join(", ")}';
    if (_products.isEmpty) return 'No products returned';
    return '';
  }
  bool get isPremium => _premiumFromPrefs;
  List<ProductDetails> get products => List.unmodifiable(_products);

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((p) => p.id == monthlyProductId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((p) => p.id == yearlyProductId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get lifetimeProduct {
    try {
      return _products.firstWhere((p) => p.id == lifetimeProductId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Initialize in-app purchase and load products. Call once at app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
        _isInitialized = true;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _isAvailable = await _inAppPurchase.isAvailable();
      _lastIsAvailable = _isAvailable;
      if (!_isAvailable) {
        _isInitialized = true;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      await _loadPremiumFromPrefs();
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (e) {
          if (kDebugMode) print('Purchase stream error: $e');
        },
      );

      await _loadProducts();
      _isInitialized = true;
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('PurchaseService init error: $e');
        print('$st');
      }
      _isInitialized = true;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadPremiumFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _premiumFromPrefs = prefs.getBool(_premiumKey) ?? false;
    } catch (_) {}
  }

  Future<void> _savePremium(bool value) async {
    if (_premiumFromPrefs == value) return;
    _premiumFromPrefs = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, value);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    _lastProductError = null;
    _lastNotFoundIds = [];
    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);
      _lastNotFoundIds = response.notFoundIDs.toList();
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        print('Product IDs not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        _products = response.productDetails;
        notifyListeners();
      } else {
        notifyListeners();
      }
    } catch (e, st) {
      _lastProductError = e.toString();
      if (kDebugMode) {
        print('queryProductDetails error: $e');
        print('$st');
      }
      notifyListeners();
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (!_productIds.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _savePremium(true);
          if (purchase.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          if (kDebugMode) {
            print('Purchase error: ${purchase.error}');
          }
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  /// Purchase a product (monthly, yearly, or lifetime). Results come via [purchaseStream]; listen to [isPremium] or this service.
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_isAvailable) return false;
    try {
      final param = PurchaseParam(productDetails: product);
      return await _inAppPurchase.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      if (kDebugMode) print('buyProduct error: $e');
      return false;
    }
  }

  /// Restore previous purchases. Premium status updates when restore events arrive on the stream.
  Future<bool> restorePurchases() async {
    if (!_isAvailable) return false;
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      if (kDebugMode) print('restorePurchases error: $e');
      return false;
    }
  }

  /// Refresh product list and premium status (e.g. after returning to paywall).
  Future<void> refresh() async {
    await _loadProducts();
    await _loadPremiumFromPrefs();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
