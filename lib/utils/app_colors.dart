import 'package:flutter/material.dart';

class AppColors {
  static ColorScheme of(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF1976D2);
  static const bottomBar = Color(0xFFF2F2F3);
}