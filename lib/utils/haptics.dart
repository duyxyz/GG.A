import 'package:flutter/services.dart';
import '../main.dart';

class AppHaptics {
  static void lightImpact() {
    if (MyApp.hapticNotifier.value) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (MyApp.hapticNotifier.value) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (MyApp.hapticNotifier.value) HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (MyApp.hapticNotifier.value) HapticFeedback.selectionClick();
  }
}
