import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/smooth_speech_to_text/smooth_grocery_voice_widget.dart';
import '../providers/grocery_provider.dart';

class VoiceFab extends StatefulWidget {
  const VoiceFab({super.key});

  static Future<void> openSheet(
    BuildContext context, {
    String? itemContextName,
  }) async {
    final grocery = context.read<GroceryProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SmoothGroceryVoiceWidget(
            groceryProvider: grocery,
            itemContextName: itemContextName,
            onClose: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    );
  }

  @override
  State<VoiceFab> createState() => _VoiceFabState();
}

class _VoiceFabState extends State<VoiceFab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        child: const Icon(Icons.mic, size: 35),
      ),
    );
  }
}
