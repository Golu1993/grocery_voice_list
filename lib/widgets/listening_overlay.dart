import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:grocery_voice_list/utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/grocery_provider.dart';

class ListeningOverlay extends StatefulWidget {
  const ListeningOverlay({super.key});

  @override
  State<ListeningOverlay> createState() => _ListeningOverlayState();
}

class _ListeningOverlayState extends State<ListeningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  bool _autoDismissScheduled = false;
  bool _retryRequested = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<VoiceProvider>().addListener(_onVoiceStatusChanged);
  }

  void _onVoiceStatusChanged() {
    if (!mounted) return;
    final voice = context.read<VoiceProvider>();
    if ((voice.status == VoiceStatus.done || voice.status == VoiceStatus.error)
        && !_autoDismissScheduled) {
      _autoDismissScheduled = true;
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && !_retryRequested) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _retry() async {
    _retryRequested = true;
    _autoDismissScheduled = false;
    final voice = context.read<VoiceProvider>();
    final grocery = context.read<GroceryProvider>();
    await voice.startListening(grocery,
        itemContextName: voice.itemContextName);
    if (mounted) setState(() => _retryRequested = false);
  }

  @override
  void dispose() {
    // Remove listener safely — provider may already be gone
    try {
      context.read<VoiceProvider>().removeListener(_onVoiceStatusChanged);
    } catch (_) {}
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final grocery = context.read<GroceryProvider>();
    final colorScheme = AppColors.of(context);
    final theme = AppColors.theme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Status icon + animation
          _buildStatusIcon(voice, colorScheme),
          const SizedBox(height: 24),

          // Status text
          Text(
            _statusText(voice),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (voice.itemContextName != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Updating: ${voice.itemContextName}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Live transcription
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: voice.liveTranscription.isNotEmpty
                ? Container(
                    key: ValueKey(voice.liveTranscription),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '"${voice.liveTranscription}"',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('placeholder'),
                    height: 56,
                    child: Center(
                      child: Text(
                        voice.status == VoiceStatus.listening
                            ? 'Say something…'
                            : voice.statusMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Close
              OutlinedButton.icon(
                onPressed: () {
                  voice.cancelListening();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stop (while listening)
              if (voice.status == VoiceStatus.listening)
                FilledButton.icon(
                  onPressed: () {
                    voice.stopListening(grocery);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              // Retry (after done or error)
              if (voice.status == VoiceStatus.done ||
                  voice.status == VoiceStatus.error)
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
            ],
          ),

          // Hint
          const SizedBox(height: 16),
          Text(
            voice.itemContextName != null
                ? 'Say: "add one more kg" • "mark done" • "delete" • "change to 500g"'
                : 'Try: "Add 2 kg potatoes" • "Doodh chahiye" • "Remove onions"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(VoiceProvider voice, ColorScheme colorScheme) {
    if (voice.status == VoiceStatus.listening) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: 80 + _pulseController.value * 20,
                height: 80 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary
                      .withOpacity(0.08 * (1 - _pulseController.value)),
                ),
              ),
              // Middle ring
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.15),
                ),
              ),
              // Inner icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              // Wave bars
              Positioned(
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) => _WaveBars(
                    progress: _waveController.value,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (voice.status == VoiceStatus.processing) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.tertiary,
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        ),
      );
    }

    if (voice.status == VoiceStatus.done) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer,
        ),
        child: Icon(Icons.check_rounded, color: colorScheme.primary, size: 32),
      );
    }

    if (voice.status == VoiceStatus.error) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.errorContainer,
        ),
        child: Icon(Icons.error_rounded, color: colorScheme.error, size: 32),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHigh,
      ),
      child: Icon(Icons.mic_off_rounded, color: colorScheme.onSurfaceVariant, size: 30),
    );
  }

  String _statusText(VoiceProvider voice) {
    switch (voice.status) {
      case VoiceStatus.listening:
        return 'Listening…';
      case VoiceStatus.processing:
        return 'Processing…';
      case VoiceStatus.done:
        return voice.statusMessage.isNotEmpty ? voice.statusMessage : 'Done!';
      case VoiceStatus.error:
        return voice.lastError;
      case VoiceStatus.permissionDenied:
        return 'Microphone permission needed';
      case VoiceStatus.idle:
        return 'Ready';
    }
  }
}

class _WaveBars extends StatelessWidget {
  final double progress;
  final Color color;

  const _WaveBars({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    const barCount = 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (i) {
        final phase = (progress + i / barCount) % 1.0;
        final height = 6 + (math.sin(phase * 2 * math.pi) + 1) * 8;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
