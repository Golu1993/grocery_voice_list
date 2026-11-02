import 'dart:async';

import 'package:flutter/material.dart';

import '../../providers/grocery_provider.dart';
import '../../services/voice_close_command.dart';
import 'smooth_grocery_command_processor.dart';
import 'smooth_speech_to_text_controller.dart';
import 'smooth_speech_to_text_widget.dart';

/// Continuous grocery command UI: speak, pause, add, then speak again.
class SmoothGroceryVoiceWidget extends StatefulWidget {
  const SmoothGroceryVoiceWidget({
    super.key,
    required this.groceryProvider,
    required this.onClose,
    this.itemContextName,
    this.height,
  });

  final GroceryProvider groceryProvider;
  final VoidCallback onClose;
  final String? itemContextName;
  final double? height;

  @override
  State<SmoothGroceryVoiceWidget> createState() =>
      _SmoothGroceryVoiceWidgetState();
}

class _SmoothGroceryVoiceWidgetState extends State<SmoothGroceryVoiceWidget> {
  late final SmoothGroceryCommandProcessor _processor;
  late final SmoothSpeechToTextController _controller;
  Future<void> _commandQueue = Future<void>.value();
  String? _activityMessage;
  int _pendingCommands = 0;
  bool _closing = false;
  bool _commandFailed = false;

  @override
  void initState() {
    super.initState();
    _processor = SmoothGroceryCommandProcessor(widget.groceryProvider);
    _controller = SmoothSpeechToTextController(localeId: 'en_IN');
  }

  void _processFinalPhrase(String phrase) {
    if (_closing) return;
    final closingCommand = VoiceCloseCommand.parse(phrase);
    if (closingCommand.commandText.isNotEmpty) {
      _queueCommand(closingCommand.commandText);
    }
    if (closingCommand.shouldClose) unawaited(_close());
  }

  void _queueCommand(String command) {
    _pendingCommands++;
    if (mounted) {
      setState(() => _activityMessage = 'Processing “$command”…');
    }

    _commandQueue = _commandQueue.then((_) async {
      String feedback;
      var succeeded = true;
      try {
        feedback = await _processor.process(
          command,
          itemContextName: widget.itemContextName,
        );
      } on FormatException catch (error) {
        succeeded = false;
        _commandFailed = true;
        feedback = error.message;
      } catch (_) {
        succeeded = false;
        _commandFailed = true;
        feedback =
            'Could not save changes. Check your connection and try again.';
      }

      _pendingCommands--;
      if (!mounted || _closing) return;
      setState(() {
        _activityMessage = succeeded
            ? _pendingCommands > 0
                  ? '✓ $feedback • Processing next command…'
                  : '✓ $feedback • Listening for the next item…'
            : feedback;
      });
    });
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    setState(() => _activityMessage = 'Finishing voice input…');
    try {
      await _controller.stop();
      await _commandQueue;
      if (!mounted) return;
      if (_commandFailed) {
        _commandFailed = false;
        _closing = false;
        setState(() {
          _activityMessage =
              'Some commands could not be saved. Tap the mic to try again, '
              'or tap Done to close.';
        });
        return;
      }
      widget.onClose();
    } catch (_) {
      if (!mounted) return;
      _closing = false;
      setState(() {
        _activityMessage =
            'Could not finish voice input. Please try Done again.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmoothSpeechToTextWidget(
      controller: _controller,
      autoStart: true,
      localeId: 'en_IN',
      localeLabel: 'English (India)',
      title: widget.itemContextName == null ? 'Add by voice' : 'Update item',
      height: widget.height,
      centeredVoiceLayout: true,
      showTranscriptActions: false,
      showMicrophoneButton: true,
      allowManualMicrophoneControl: !_closing,
      clearAfterFinalPhrase: true,
      submitPendingPhraseOnStop: true,
      submitPendingPhraseOnClose: true,
      activityMessage: _activityMessage,
      onFinalPhrase: _processFinalPhrase,
      onClose: () => unawaited(_close()),
    );
  }
}
