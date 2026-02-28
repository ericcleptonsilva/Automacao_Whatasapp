import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String nativeAdUnitId = 'ca-app-pub-7443083882734789/7000598868';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Returning test banner ID as nativeAdUnitId is incompatible with BannerAd
      return testBannerId;
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
