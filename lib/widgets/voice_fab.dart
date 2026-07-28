import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/grocery_provider.dart';
import 'listening_overlay.dart';

class VoiceFab extends StatefulWidget {
  const VoiceFab({super.key});

  static Future<void> openSheet(BuildContext context,
      {String? itemContextName}) async {
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

class _VoiceFabState extends State<VoiceFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final grocery = context.watch<GroceryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isListening = voice.isListening;
    final hasItems = grocery.totalItems > 0;

    final bgColor = isListening ? colorScheme.error : colorScheme.primary;
    final fgColor = isListening ? colorScheme.onError : colorScheme.onPrimary;

    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        isListening ? Icons.stop_rounded : Icons.mic_rounded,
        key: ValueKey(isListening),
        color: fgColor,
        size: 22,
      ),
    );

    final label = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        isListening
            ? 'Listening…'
            : hasItems
                ? 'Add more'
                : 'Add Item',
        key: ValueKey('$isListening$hasItems'),
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: isListening ? _scaleAnim.value : 1.0,
        child: child,
      ),
      child: FloatingActionButton.extended(
        onPressed: () => VoiceFab.openSheet(context),
        backgroundColor: bgColor,
        elevation: isListening ? 8 : 4,
        icon: icon,
        label: label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
