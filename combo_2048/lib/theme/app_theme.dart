import 'package:combo_2048/theme/grid-peoperties.dart' as gp;
import 'package:flutter/material.dart';

enum AppTheme { dark, minecraft, original }

class GameColors extends ThemeExtension<GameColors> {
  final Color boardBg;
  final Color boardBorder;
  final Color tileEmpty;
  final Color textPrimary;
  final Map<int, Color> tileByValue;

  const GameColors({required this.boardBg, required this.boardBorder, required this.tileEmpty, required this.textPrimary, required this.tileByValue});

  Color colorFor(int value) => tileByValue[value] ?? tileEmpty;

  @override
  ThemeExtension<GameColors> copyWith({Color? boardBg, Color? boardBorder, Color? tileEmpty, Color? textPrimary, Map<int, Color>? tileByValue}) {
    return GameColors(
      boardBg: boardBg ?? this.boardBg,
      boardBorder: boardBorder ?? this.boardBorder,
      tileEmpty: tileEmpty ?? this.tileEmpty,
      textPrimary: textPrimary ?? this.textPrimary,
      tileByValue: tileByValue ?? this.tileByValue,
    );
  }

  @override
  ThemeExtension<GameColors> lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    Map<int, Color> lerpMap(Map<int, Color> a, Map<int, Color> b) {
      final keys = {...a.keys, ...b.keys};
      return {for (final k in keys) k: lerpC(a[k] ?? a.values.first, b[k] ?? b.values.first)};
    }

    return GameColors(
      boardBg: lerpC(boardBg, other.boardBg),
      boardBorder: lerpC(boardBorder, other.boardBorder),
      tileEmpty: lerpC(tileEmpty, other.tileEmpty),
      textPrimary: lerpC(textPrimary, other.textPrimary),
      tileByValue: lerpMap(tileByValue, other.tileByValue),
    );
  }
}

ThemeData buildTheme(AppTheme which) {
  switch (which) {
    case AppTheme.original:
      return ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(primary: gp.orange, surface: gp.tan, onSurface: gp.greyText),
        scaffoldBackgroundColor: gp.tan,
        textTheme: const TextTheme(headlineMedium: TextStyle(fontWeight: FontWeight.w700)),
        extensions: [
          GameColors(
            boardBg: gp.darkBrown,
            boardBorder: const Color(0xFFB2A89E),
            tileEmpty: gp.lightBrown,
            textPrimary: gp.greyText,
            tileByValue: gp.numTileColor, // usa o mapa original
          ),
        ],
      );
    case AppTheme.dark:
      final scheme = const ColorScheme.dark(
        primary: Color(0xFFFFA24A),
        secondary: Color(0xFF8BC34A),
        surface: Color(0xFF303030),
        onSurface: Color(0xFFEFEFEF),
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(headlineMedium: TextStyle(fontWeight: FontWeight.w700)),
        extensions: [
          GameColors(
            boardBg: const Color(0xFF3B3B3B),
            boardBorder: const Color(0xFF4A4A4A),
            tileEmpty: const Color(0xFF4F4F4F),
            textPrimary: Colors.white,
            tileByValue: const {
              2: Color(0xFFEEE4DA),
              4: Color(0xFFEDE0C8),
              8: Color(0xFFF2B179),
              16: Color(0xFFF59563),
              32: Color(0xFFF67C5F),
              64: Color(0xFFF65E3B),
              128: Color(0xFFEDCF72),
              256: Color(0xFFECCB61),
              512: Color(0xFFECC64A),
              1024: Color(0xFFE5C254),
              2048: Color(0xFFE8C34A),
            },
          ),
        ],
      );

    case AppTheme.minecraft:
      final scheme = const ColorScheme.dark(
        primary: Color(0xFF5AA13C),
        secondary: Color(0xFF8B5A2B),
        surface: Color(0xFF2B2B2B),
        onSurface: Color(0xFFEFEFEF),
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF1A1F14),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          bodyLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
        extensions: [
          GameColors(
            boardBg: const Color(0xFF364427),
            boardBorder: const Color(0xFF253018),
            tileEmpty: const Color(0xFF29351E),
            textPrimary: const Color(0xFFFAF9F6),
            tileByValue: const {
              2: Color(0xFFD7C9A3),
              4: Color(0xFFC7B48A),
              8: Color(0xFFB8863B),
              16: Color(0xFFA9742E),
              32: Color(0xFF9C5D20),
              64: Color(0xFF8B4513),
              128: Color(0xFF7E9C63),
              256: Color(0xFF6F8F57),
              512: Color(0xFF5E7F49),
              1024: Color(0xFF8C8C8C),
              2048: Color(0xFFB5A642),
            },
          ),
        ],
      );
  }
}
