import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/grocery_provider.dart';
import '../providers/voice_provider.dart';
import 'listening_overlay.dart';

class VoiceFab extends StatefulWidget {
  const VoiceFab({super.key});

  static Future<void> openSheet(
    BuildContext context, {
    String? itemContextName,
  }) async {
    final voice = context.read<VoiceProvider>();
    final grocery = context.read<GroceryProvider>();

    await voice.initialize();
    await voice.startListening(grocery, itemContextName: itemContextName);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: voice),
          ChangeNotifierProvider.value(value: grocery),
        ],
        child: const ListeningOverlay(),
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
        onPressed: () => {
          print('============'),
          VoiceFab.openSheet(context)},
        child: const Icon(Icons.mic, size: 35),
      ),
    );
  }
}
