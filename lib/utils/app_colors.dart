import 'package:flutter/material.dart';

class AppColors {
  static ColorScheme of(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  static ThemeData theme(BuildContext context) {
    return Theme.of(context);
  }
  static const primary = Color(0xFF1478ED);
  static const secondary = Color(0xFF5B49FF);
  static const bottomBar = Color(0xFFF2F2F3);
}