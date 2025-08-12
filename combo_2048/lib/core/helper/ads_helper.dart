import 'dart:io';

class AdIds {
  static String get banner =>
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // TEST ANDROID
          : 'ca-app-pub-3940256099942544/2934735716'; // TEST iOS

  static String get interstitial =>
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // TEST ANDROID
          : 'ca-app-pub-3940256099942544/4411468910'; // TEST iOS

  static String get mrec => // 300x250
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // TEST ANDROID (serve p/ banner/MREC de teste)
          : 'ca-app-pub-3940256099942544/2934735716'; // TEST iOS
}
