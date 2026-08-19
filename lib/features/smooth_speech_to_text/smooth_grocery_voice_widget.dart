import 'dart:async';

import 'package:flutter/material.dart';

import '../../providers/grocery_provider.dart';
import 'smooth_grocery_command_processor.dart';
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
  Future<void> _commandQueue = Future<void>.value();
  String? _activityMessage;
  int _pendingCommands = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _processor = SmoothGroceryCommandProcessor(widget.groceryProvider);
  }

  void _processFinalPhrase(String phrase) {
    final command = phrase.trim();
    if (command.isEmpty || _closing) return;

    _pendingCommands++;
    if (mounted) {
      setState(() => _activityMessage = 'Processing “$command”…');
    }

    _commandQueue = _commandQueue.then((_) async {
      String feedback;
      try {
        feedback = await _processor.process(
          command,
          itemContextName: widget.itemContextName,
        );
      } catch (_) {
        feedback = 'Could not update the grocery list';
      }

      _pendingCommands--;
      if (!mounted || _closing) return;
      setState(() {
        _activityMessage = _pendingCommands > 0
            ? '✓ $feedback • Processing next command…'
            : '✓ $feedback • Listening for the next item…';
      });
    });
  }

  void _close() {
    _closing = true;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return SmoothSpeechToTextWidget(
      autoStart: true,
      title: widget.itemContextName == null
          ? 'Add groceries by voice'
          : 'Update ${widget.itemContextName}',
      height: widget.height,
      showTranscriptActions: false,
      showMicrophoneButton: false,
      clearAfterFinalPhrase: true,
      transcriptAreaHeight: 94,
      activityMessage: _activityMessage,
      onFinalPhrase: _processFinalPhrase,
      onClose: _close,
    );
  }
}
