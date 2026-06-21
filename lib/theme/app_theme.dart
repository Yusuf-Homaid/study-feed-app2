import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme definition that mimics X's (Twitter's) Pure Black mode.
class AppColors {
  static const Color pureBlack = Color(0xFF000000);
  static const Color cardGrey = Color(0xFF16181C); // subtle dark grey card
  static const Color borderGrey = Color(0xFF2F3336);
  static const Color secondaryText = Color(0xFF71767B);
  static const Color blue = Color(0xFF1D9BF0); // X accent blue
  static const Color likePink = Color(0xFFF91880);
  static const Color retweetGreen = Color(0xFF00BA7C);
  static const Color white = Color(0xFFE7E9EA);
}

/// Supported readable fonts for accessibility font-switcher.
enum AppFontFamily { roboto, inter, arial, system }

extension AppFontFamilyX on AppFontFamily {
  String get label {
    switch (this) {
      case AppFontFamily.roboto:
        return 'Roboto';
      case AppFontFamily.inter:
        return 'Inter';
      case AppFontFamily.arial:
        return 'Arial';
      case AppFontFamily.system:
        return 'System Default';
    }
  }

  TextStyle textStyle({double fontSize = 15, FontWeight? weight, Color? color}) {
    switch (this) {
      case AppFontFamily.roboto:
        return GoogleFonts.roboto(fontSize: fontSize, fontWeight: weight, color: color);
      case AppFontFamily.inter:
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: weight, color: color);
      case AppFontFamily.arial:
        // Arial isn't on Google Fonts; Arimo is an open metric-compatible match.
        return GoogleFonts.arimo(fontSize: fontSize, fontWeight: weight, color: color);
      case AppFontFamily.system:
        return TextStyle(fontSize: fontSize, fontWeight: weight, color: color);
    }
  }
}

class AppTheme {
  static ThemeData darkPure() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.pureBlack,
      primaryColor: AppColors.blue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        surface: AppColors.pureBlack,
        background: AppColors.pureBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      dividerColor: AppColors.borderGrey,
      cardColor: AppColors.cardGrey,
      splashColor: AppColors.blue.withOpacity(0.1),
      highlightColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.secondaryText),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardGrey,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardGrey,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
