import 'package:combo_2048/features/game/pages/twenty_forty_eight.dart';
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class MyApp extends StatelessWidget {
  final ThemeController themeController;
  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          home: TwentyFortyEight(themeController: themeController),
        );
      },
    );
  }
}
