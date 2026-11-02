import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'smooth_speech_state.dart';
import 'smooth_speech_to_text_controller.dart';

/// Fully standalone speech-to-text UI with no grocery feature dependencies.
class SmoothSpeechToTextWidget extends StatefulWidget {
  const SmoothSpeechToTextWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onFinalPhrase,
    this.onClose,
    this.autoStart = false,
    this.initialText = '',
    this.localeId,
    this.title = 'Speech to text',
    this.height = 520,
    this.showTranscriptActions = true,
    this.showMicrophoneButton = true,
    this.allowManualMicrophoneControl = true,
    this.clearAfterFinalPhrase = false,
    this.submitPendingPhraseOnStop = false,
    this.submitPendingPhraseOnClose = false,
    this.transcriptAreaHeight,
    this.activityMessage,
    this.localeLabel,
    this.centeredVoiceLayout = false,
  });

  final SmoothSpeechToTextController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFinalPhrase;
  final VoidCallback? onClose;
  final bool autoStart;
  final String initialText;
  final String? localeId;
  final String title;
  final double? height;
  final bool showTranscriptActions;
  final bool showMicrophoneButton;
  final bool allowManualMicrophoneControl;
  final bool clearAfterFinalPhrase;
  final bool submitPendingPhraseOnStop;
  final bool submitPendingPhraseOnClose;
  final double? transcriptAreaHeight;
  final String? activityMessage;
  final String? localeLabel;
  final bool centeredVoiceLayout;

  @override
  State<SmoothSpeechToTextWidget> createState() =>
      _SmoothSpeechToTextWidgetState();
}

class _SmoothSpeechToTextWidgetState extends State<SmoothSpeechToTextWidget> {
  late SmoothSpeechToTextController _controller;
  late bool _ownsController;
  String _lastReportedText = '';

  @override
  void initState() {
    super.initState();
    _attachController();
    if (widget.initialText.trim().isNotEmpty && !_controller.hasText) {
      _controller.replaceText(widget.initialText);
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.start());
      });
    }
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SmoothSpeechToTextController(localeId: widget.localeId);
    _controller.addListener(_controllerChanged);
    _controller.onFinalPhrase = _handleFinalPhrase;
    _lastReportedText = _controller.transcript;
  }

  @override
  void didUpdateWidget(covariant SmoothSpeechToTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _controller.removeListener(_controllerChanged);
      if (_ownsController) _controller.dispose();
      _attachController();
    }
    _controller.localeId = widget.localeId;
    _controller.onFinalPhrase = _handleFinalPhrase;
  }

  void _handleFinalPhrase(String phrase) {
    widget.onFinalPhrase?.call(phrase);
    if (widget.clearAfterFinalPhrase) {
      _controller.clear();
      _lastReportedText = '';
    }
  }

  void _controllerChanged() {
    if (!mounted) return;
    final text = _controller.transcript;
    if (text != _lastReportedText) {
      _lastReportedText = text;
      widget.onChanged?.call(text);
    }
    setState(() {});
  }

  Future<void> _copyTranscript() async {
    if (!_controller.hasText) return;
    await Clipboard.setData(ClipboardData(text: _controller.transcript));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Transcript copied')));
  }

  Future<void> _close() async {
    if (_controller.isActive) {
      await _controller.stop(
        submitPendingPhrase: widget.submitPendingPhraseOnClose,
      );
    }
    if (mounted) widget.onClose?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = _controller.state;
    final active = state.isActive;
    final hasRecognitionError =
        state == SmoothSpeechState.error ||
        state == SmoothSpeechState.unavailable;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: widget.centeredVoiceLayout
              ? const EdgeInsets.fromLTRB(16, 12, 16, 14)
              : const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: widget.height == null
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              _buildHeader(theme, colors),
              SizedBox(height: widget.centeredVoiceLayout ? 8 : 18),
              if (widget.centeredVoiceLayout)
                Expanded(
                  child: _buildCenteredVoiceContent(
                    theme,
                    colors,
                    state,
                    active,
                    hasRecognitionError,
                  ),
                )
              else ...[
                if (widget.transcriptAreaHeight == null)
                  Expanded(child: _buildTranscriptArea(theme, colors, active))
                else
                  SizedBox(
                    height: widget.transcriptAreaHeight,
                    child: _buildTranscriptArea(theme, colors, active),
                  ),
                const SizedBox(height: 14),
                _buildStatusText(theme, colors, state, hasRecognitionError),
                _buildWaveform(colors, active),
                if (widget.localeLabel != null) ...[
                  const SizedBox(height: 8),
                  _buildLocaleLabel(theme, colors),
                ],
                if (widget.showMicrophoneButton) ...[
                  const SizedBox(height: 14),
                  _buildMicrophoneButton(colors, active),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    if (widget.centeredVoiceLayout) {
      return SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.onClose == null ? 0 : 74,
              ),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.onClose != null)
              Align(
                alignment: Alignment.centerRight,
                child: _buildDoneButton(colors, compact: true),
              ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (widget.showTranscriptActions) ...[
          IconButton(
            tooltip: 'Clear transcript',
            onPressed: _controller.hasText ? _controller.clear : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Copy transcript',
            onPressed: _controller.hasText ? _copyTranscript : null,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
        if (widget.onClose != null) _buildDoneButton(colors),
      ],
    );
  }

  Widget _buildDoneButton(ColorScheme colors, {bool compact = false}) {
    final style = FilledButton.styleFrom(
      backgroundColor: colors.primary,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 14,
        vertical: compact ? 9 : 10,
      ),
      visualDensity: VisualDensity.compact,
    );

    if (compact) {
      return FilledButton(
        onPressed: _close,
        style: style,
        child: const Text('Done', style: TextStyle(color: Colors.white)),
      );
    }

    return FilledButton.icon(
      onPressed: _close,
      icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      label: const Text('Done', style: TextStyle(color: Colors.white)),
      style: style,
    );
  }

  Widget _buildCenteredVoiceContent(
    ThemeData theme,
    ColorScheme colors,
    SmoothSpeechState state,
    bool active,
    bool hasRecognitionError,
  ) {
    final spokenText = _controller.transcript.trim();
    final feedbackText = widget.activityMessage?.trim() ?? '';
    final primaryText = hasRecognitionError
        ? _statusText(state)
        : spokenText.isNotEmpty
        ? spokenText
        : feedbackText.isNotEmpty
        ? feedbackText
        : state == SmoothSpeechState.starting
        ? 'Starting microphone…'
        : active
        ? 'Speak now'
        : 'Tap the microphone to speak';

    return Column(
      children: [
        const Spacer(),
        if (widget.showMicrophoneButton)
          _buildMicrophoneButton(colors, active, prominent: true),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: SingleChildScrollView(
            reverse: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                primaryText,
                key: ValueKey(primaryText),
                textAlign: TextAlign.center,
                style:
                    (feedbackText.isNotEmpty && spokenText.isEmpty
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleLarge)
                        ?.copyWith(
                          color: hasRecognitionError
                              ? colors.error
                              : colors.onSurface,
                          fontWeight: spokenText.isEmpty
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.35,
                        ),
              ),
            ),
          ),
        ),
        const Spacer(),
        if (widget.localeLabel != null) _buildLocaleLabel(theme, colors),
      ],
    );
  }

  Widget _buildStatusText(
    ThemeData theme,
    ColorScheme colors,
    SmoothSpeechState state,
    bool hasRecognitionError,
  ) {
    return Text(
      hasRecognitionError
          ? _statusText(state)
          : widget.activityMessage ?? _statusText(state),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        color: hasRecognitionError ? colors.error : colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWaveform(ColorScheme colors, bool active) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: active
          ? Padding(
              key: const ValueKey('listening-waveform'),
              padding: const EdgeInsets.only(top: 8),
              child: _ListeningWaveform(
                soundLevel: _controller.soundLevel,
                color: colors.primary,
              ),
            )
          : const SizedBox(
              key: ValueKey('listening-waveform-hidden'),
              height: 50,
            ),
    );
  }

  Widget _buildLocaleLabel(ThemeData theme, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.language_rounded, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            widget.localeLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicrophoneButton(
    ColorScheme colors,
    bool active, {
    bool prominent = false,
  }) {
    final buttonSize = prominent ? 78.0 : 70.0;
    final haloSize = prominent ? 92.0 : 82.0;
    final pulseGrowth = prominent ? 16.0 : 18.0;

    return ValueListenableBuilder<double>(
      valueListenable: _controller.soundLevel,
      builder: (context, level, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween(end: active ? level : 0),
          duration: const Duration(milliseconds: 90),
          builder: (context, animatedLevel, animatedChild) => Container(
            width: haloSize + (animatedLevel * pulseGrowth),
            height: haloSize + (animatedLevel * pulseGrowth),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(
                alpha: active ? 0.10 + (animatedLevel * 0.12) : 0.07,
              ),
            ),
            child: animatedChild,
          ),
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: FloatingActionButton(
              heroTag: null,
              elevation: active ? 3 : 1,
              tooltip: widget.allowManualMicrophoneControl
                  ? active
                        ? 'Stop listening'
                        : 'Start listening'
                  : 'Listening',
              onPressed: widget.allowManualMicrophoneControl
                  ? active
                        ? () => _controller.stop(
                            submitPendingPhrase:
                                widget.submitPendingPhraseOnStop,
                          )
                        : _controller.start
                  : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  prominent
                      ? Icons.mic_rounded
                      : widget.allowManualMicrophoneControl && active
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  key: ValueKey('$prominent-$active'),
                  size: prominent ? 38 : 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranscriptArea(
    ThemeData theme,
    ColorScheme colors,
    bool active,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer.withValues(alpha: 0.30)
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
          width: active ? 1.5 : 1,
        ),
      ),
      child: _controller.hasText
          ? SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                _controller.transcript,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: colors.onSurface,
                ),
              ),
            )
          : Center(
              child: Text(
                'Start speaking naturally…',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
    );
  }

  String _statusText(SmoothSpeechState state) {
    switch (state) {
      case SmoothSpeechState.idle:
        return _controller.hasText ? 'Paused' : 'Ready to listen';
      case SmoothSpeechState.starting:
        return 'Starting microphone…';
      case SmoothSpeechState.listening:
        return 'Listening continuously…';
      case SmoothSpeechState.stopping:
        return 'Finishing transcript…';
      case SmoothSpeechState.unavailable:
      case SmoothSpeechState.error:
        return _controller.errorMessage;
    }
  }
}

class _ListeningWaveform extends StatefulWidget {
  const _ListeningWaveform({required this.soundLevel, required this.color});

  final ValueListenable<double> soundLevel;
  final Color color;

  @override
  State<_ListeningWaveform> createState() => _ListeningWaveformState();
}

class _ListeningWaveformState extends State<_ListeningWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Microphone is listening',
      child: SizedBox(
        height: 50,
        child: AnimatedBuilder(
          animation: Listenable.merge([_animation, widget.soundLevel]),
          builder: (context, _) {
            final level = widget.soundLevel.value.clamp(0.0, 1.0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(9, (index) {
                final phase =
                    (_animation.value * math.pi * 2) + (index * math.pi / 3.2);
                final wave = (math.sin(phase) + 1) / 2;
                final centerWeight = 1 - ((index - 4).abs() / 6);
                final height =
                    20 +
                    (wave * 10 * centerWeight) +
                    (level * 14 * centerWeight);

                return Container(
                  width: 4,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: 0.52 + (level * 0.38),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
