import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'purchase_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Test Ad Unit IDs for Android - Replace with your actual ad unit IDs in production
  static const String _bannerAdUnitId = 'ca-app-pub-5876607751934203/3751654734';
  static const String _interstitialAdUnitId = 'ca-app-pub-5876607751934203/2358682018';

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  bool _isBannerAdLoaded = false;

  // Premium status checking
  final PurchaseService _purchaseService = PurchaseService();

  /// Check if user has premium (no ads)
  bool get isPremium => _purchaseService.isPremium;

  // Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Get banner ad unit ID (Android only)
  String get bannerAdUnitId {
    return _bannerAdUnitId;
  }

  // Get interstitial ad unit ID (Android only)
  String get interstitialAdUnitId {
    return _interstitialAdUnitId;
  }

  // Load banner ad (Android only)
  BannerAd? loadBannerAd() {
    // Don't load ads for premium users
    if (isPremium) {
      print(' Premium user - no banner ads');
      return null;
    }

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          _isBannerAdLoaded = false;
          ad.dispose();
        },
        onAdOpened: (ad) => print('Banner ad opened'),
        onAdClosed: (ad) => print('Banner ad closed'),
      ),
    );
    _bannerAd!.load();
    return _bannerAd!;
  }

  // Create banner ad (backward compatibility)
  BannerAd? createBannerAd() {
    return loadBannerAd();
  }

  // Load interstitial ad (Android only)
  void loadInterstitialAd() {
    // Don't load ads for premium users
    if (isPremium) {
      print('🎉 Premium user - no interstitial ads');
      return;
    }


    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          // Set full screen content callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('Interstitial ad showed full screen content');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('Interstitial ad dismissed full screen content');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Load next interstitial ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show full screen content: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Load next interstitial ad
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // Show interstitial ad (Android only)
  void showInterstitialAd() {

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('Interstitial ad not loaded yet');
      // Load an ad if not already loaded
      if (!_isInterstitialAdLoaded) {
        loadInterstitialAd();
      }
    }
  }

  // Check if banner ad is loaded
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  // Check if interstitial ad is loaded
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  // Get banner ad instance
  BannerAd? get bannerAd => _bannerAd;

  // Dispose ads
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
  }
}
