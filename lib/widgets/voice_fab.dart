import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/smooth_speech_to_text/smooth_grocery_voice_widget.dart';
import '../providers/grocery_provider.dart';

class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key});

  static Future<void> openSheet(
    BuildContext context, {
    String? itemContextName,
  }) async {
    final grocery = context.read<GroceryProvider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final screen = MediaQuery.sizeOf(dialogContext);
        final dialogSize = math.min(
          520.0,
          math.min(screen.width - 32, screen.height - 96),
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: SizedBox.square(
            dimension: dialogSize,
            child: SmoothGroceryVoiceWidget(
              groceryProvider: grocery,
              itemContextName: itemContextName,
              height: dialogSize,
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () => VoiceFab.openSheet(context),
        tooltip: 'Add groceries by voice',
        child: const Icon(Icons.mic_rounded, size: 35),
      ),
    );
  }
}
