import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Manages global accessibility settings: font scale (A+ / A-)
/// and font family (Roboto / Inter / Arial / System).
class SettingsProvider extends ChangeNotifier {
  double _fontScale = 1.0; // multiplier applied to all feed text
  AppFontFamily _fontFamily = AppFontFamily.inter;

  static const double _minScale = 0.75;
  static const double _maxScale = 1.75;
  static const double _step = 0.1;

  double get fontScale => _fontScale;
  AppFontFamily get fontFamily => _fontFamily;

  void increaseFont() {
    if (_fontScale + _step <= _maxScale) {
      _fontScale = double.parse((_fontScale + _step).toStringAsFixed(2));
      notifyListeners();
    }
  }

  void decreaseFont() {
    if (_fontScale - _step >= _minScale) {
      _fontScale = double.parse((_fontScale - _step).toStringAsFixed(2));
      notifyListeners();
    }
  }

  void setFontFamily(AppFontFamily family) {
    _fontFamily = family;
    notifyListeners();
  }

  /// Convenience helper: returns a scaled TextStyle for the current font family.
  TextStyle scaledStyle({
    double baseSize = 15,
    FontWeight? weight,
    Color? color,
  }) {
    return _fontFamily.textStyle(
      fontSize: baseSize * _fontScale,
      weight: weight,
      color: color,
    );
  }
}
