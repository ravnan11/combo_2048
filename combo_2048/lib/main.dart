import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //DESCOMENTE EM DESENVOLVIMENTO e troque pelos seus device IDs
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: const <String>[
        'YOUR_TEST_DEVICE_ID_1',
        // 'YOUR_TEST_DEVICE_ID_2',
      ],
    ),
  );

  await MobileAds.instance.initialize();

  final themeController = ThemeController();
  runApp(MyApp(themeController: themeController));
}
