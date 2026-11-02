import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/voice_parser.dart';
import 'grocery_provider.dart';

enum VoiceStatus {
  idle,
  preparing,
  listening,
  processing,
  done,
  error,
  permissionDenied,
}

class VoiceProvider extends ChangeNotifier {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();

  VoiceStatus _status = VoiceStatus.idle;
  String _liveTranscription = '';
  String _statusMessage = '';
  String _lastError = '';
  String? _itemContextName; // Pre-seeded when mic is tapped on a list item.
  bool _isInitialized = false;
  bool _commandHandled = false;
  int _sessionId = 0;
  Timer? _finalizationTimer;
  Timer? _resetTimer;

  VoiceStatus get status => _status;
  String get liveTranscription => _liveTranscription;
  String get statusMessage => _statusMessage;
  String get lastError => _lastError;
  String? get itemContextName => _itemContextName;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isProcessing => _status == VoiceStatus.processing;

  /// Warms the native recognizer without showing an unsolicited permission
  /// prompt. First-time users are still prompted only after tapping the mic.
  Future<void> warmUpIfPermitted() async {
    if (_isInitialized) return;
    final microphone = await Permission.microphone.status;
    if (!microphone.isGranted) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final speech = await Permission.speech.status;
      if (!speech.isGranted) return;
    }
    await initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    final available = await _speech.initialize();
    _isInitialized = available;
    if (!available) {
      _status = VoiceStatus.permissionDenied;
      _statusMessage = 'Microphone permission required';
      notifyListeners();
    }
  }

  Future<void> startListening(
    GroceryProvider groceryProvider, {
    String? itemContextName,
  }) async {
    if (_status == VoiceStatus.listening ||
        _status == VoiceStatus.preparing ||
        _status == VoiceStatus.processing) {
      return;
    }

    final sessionId = ++_sessionId;
    _finalizationTimer?.cancel();
    _resetTimer?.cancel();
    unawaited(_tts.stop());

    if (!_isInitialized) {
      _status = VoiceStatus.preparing;
      _statusMessage = 'Starting microphone…';
      _lastError = '';
      _itemContextName = itemContextName;
      notifyListeners();
      await initialize();
    }
    if (sessionId != _sessionId) return;
    if (_status == VoiceStatus.permissionDenied) return;

    _liveTranscription = '';
    _statusMessage = 'Listening…';
    _lastError = '';
    _itemContextName = itemContextName;
    _commandHandled = false;
    _status = VoiceStatus.listening;
    notifyListeners();

    await _speech.startListening(
      onResult: (text, isFinal) {
        if (sessionId != _sessionId || _commandHandled) return;
        _liveTranscription = text;
        notifyListeners();

        if (isFinal && text.isNotEmpty) {
          unawaited(_finalizeCommand(text, groceryProvider, sessionId));
        }
      },
      onStatus: (status) {
        if (sessionId != _sessionId || _commandHandled) return;
        if (status == 'done' || status == 'notListening') {
          _scheduleFinalization(groceryProvider, sessionId);
        }
      },
      onError: (error) {
        if (sessionId != _sessionId || _commandHandled) return;
        if (error != 'error_speech_timeout' && error != 'error_no_match') {
          _finalizationTimer?.cancel();
          _lastError = error;
          _status = VoiceStatus.error;
          _statusMessage = 'Error: $error';
          notifyListeners();
        } else if (_liveTranscription.trim().isNotEmpty) {
          unawaited(
            _finalizeCommand(_liveTranscription, groceryProvider, sessionId),
          );
        } else {
          _setNoSpeechError();
        }
      },
    );
  }

  Future<void> stopListening(GroceryProvider groceryProvider) async {
    // Start processing the latest partial result immediately. Waiting for the
    // native recognizer's final callback can otherwise make the Done button
    // feel unresponsive.
    unawaited(_speech.stopListening());
    if (_liveTranscription.isNotEmpty) {
      await _finalizeCommand(_liveTranscription, groceryProvider, _sessionId);
    } else {
      _setNoSpeechError();
    }
  }

  Future<void> cancelListening() async {
    _sessionId++;
    _finalizationTimer?.cancel();
    _resetTimer?.cancel();
    await _speech.cancelListening();
    _status = VoiceStatus.idle;
    _liveTranscription = '';
    _statusMessage = '';
    _itemContextName = null;
    _commandHandled = false;
    notifyListeners();
  }

  void _setNoSpeechError() {
    _finalizationTimer?.cancel();
    _lastError = 'No speech detected';
    _status = VoiceStatus.error;
    _statusMessage = 'No speech detected';
    notifyListeners();
  }

  void _scheduleFinalization(GroceryProvider groceryProvider, int sessionId) {
    if (_status != VoiceStatus.listening) return;
    _finalizationTimer?.cancel();
    // Some recognizers report `done` just before their last result. This tiny
    // grace period preserves the last word without adding perceptible delay.
    _finalizationTimer = Timer(const Duration(milliseconds: 120), () {
      if (sessionId != _sessionId || _commandHandled) return;
      final text = _liveTranscription.trim();
      if (text.isEmpty) {
        _setNoSpeechError();
      } else {
        unawaited(_finalizeCommand(text, groceryProvider, sessionId));
      }
    });
  }

  Future<void> _finalizeCommand(
    String text,
    GroceryProvider groceryProvider,
    int sessionId,
  ) async {
    if (sessionId != _sessionId || _commandHandled || text.trim().isEmpty) {
      return;
    }
    _finalizationTimer?.cancel();
    unawaited(_speech.stopListening());
    await _processCommand(text.trim(), groceryProvider);
  }

  Future<void> _processCommand(
    String text,
    GroceryProvider groceryProvider,
  ) async {
    if (_commandHandled || text.trim().isEmpty) return;
    _commandHandled = true;
    _status = VoiceStatus.processing;
    _statusMessage = 'Processing…';
    notifyListeners();

    var command = VoiceParser.parse(text);
    // Fall back to pre-seeded item name when user speaks short commands
    // like "add one more" or "mark done" from within a list item
    if (_itemContextName != null && command.itemName == null) {
      command = ParsedCommand(
        action: command.action,
        itemName: _itemContextName,
        quantity: command.quantity,
        unit: command.unit,
        categoryKey: command.categoryKey,
        rawText: command.rawText,
      );
    }
    String? feedback;

    try {
      switch (command.action) {
        case CommandAction.add:
          if (command.itemName != null) {
            feedback = await groceryProvider.addItem(
              name: command.itemName!,
              quantity: command.quantity ?? 1.0,
              unit: command.unit ?? 'piece',
              categoryKey: command.categoryKey ?? 'other',
            );
          }
          break;

        case CommandAction.addMore:
          if (command.itemName != null) {
            feedback = await groceryProvider.addMoreToItem(
              command.itemName!,
              command.quantity ?? 1.0,
              command.unit ?? 'piece',
            );
          }
          break;

        case CommandAction.subtractQuantity:
          if (command.itemName != null) {
            feedback = await groceryProvider.subtractFromItem(
              command.itemName!,
              command.quantity ?? 1.0,
              command.unit ?? 'piece',
            );
          }
          break;

        case CommandAction.setQuantity:
          if (command.itemName != null && command.quantity != null) {
            feedback = await groceryProvider.setItemQuantity(
              command.itemName!,
              command.quantity!,
              command.unit ?? 'piece',
            );
          }
          break;

        case CommandAction.remove:
          final target = command.itemName ?? _itemContextName;
          if (target != null) {
            feedback = await groceryProvider.deleteItemByName(target);
          }
          break;

        case CommandAction.check:
          final target = command.itemName ?? _itemContextName;
          if (target != null) {
            feedback = await groceryProvider.checkItemByName(target);
          }
          break;

        case CommandAction.undo:
          await groceryProvider.undo();
          feedback = 'Undone';
          break;

        case CommandAction.clear:
          await groceryProvider.clearAll();
          feedback = 'List cleared';
          break;

        case CommandAction.uncheck:
          break;

        case CommandAction.unknown:
          feedback =
              'Sorry, I didn\'t understand that. Try: "add 2 kg tomatoes"';
          break;
      }
    } catch (error) {
      _lastError = '$error';
      _status = VoiceStatus.error;
      _statusMessage = 'Could not update the list. Check your connection.';
      notifyListeners();
      return;
    }

    _status = VoiceStatus.done;
    _statusMessage = feedback ?? 'Done';
    notifyListeners();

    // Speak confirmation
    if (feedback != null) unawaited(_tts.speak(feedback));

    final completedSession = _sessionId;
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (_status == VoiceStatus.done && completedSession == _sessionId) {
        _status = VoiceStatus.idle;
        _liveTranscription = '';
        _statusMessage = '';
        _itemContextName = null;
        notifyListeners();
      }
    });
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _finalizationTimer?.cancel();
    _resetTimer?.cancel();
    _speech.dispose();
    _tts.dispose();
    super.dispose();
  }
}
