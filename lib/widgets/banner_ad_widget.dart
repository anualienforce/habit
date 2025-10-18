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
    // Only load ads on Android
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      _bannerAd = AdMobService().createBannerAd();
      _bannerAd!.load().then((_) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      });
    } catch (e) {
      print('Failed to load banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
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
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded) {
      return Container(
        height: 50,
        margin: widget.margin,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: _bannerAd!.size.height.toDouble(),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
