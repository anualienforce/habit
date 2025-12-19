import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../services/purchase_service.dart';

class BannerAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final bool showOnlyWhenLoaded;

  const BannerAdWidget({
    super.key,
    this.margin,
    this.showOnlyWhenLoaded = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Only load ads on Android and when not premium.
    if (PurchaseService().isPremium || !Platform.isAndroid) return;

    try {
      final service = AdMobService();
      _bannerAd = BannerAd(
        adUnitId: service.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) return;
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      // Swallow errors to avoid breaking layout.
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _isAdLoaded = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for premium users
    if (PurchaseService().isPremium) {
      return const SizedBox.shrink();
    }

    // Only show ads on Android
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _bannerAd == null) {
      // Do not reserve space when no ad is loaded.
      return const SizedBox.shrink();
    }

    return Container(
      height: _bannerAd!.size.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
