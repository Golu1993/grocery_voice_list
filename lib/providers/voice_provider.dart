import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/voice_parser.dart';
import 'grocery_provider.dart';

enum VoiceStatus { idle, listening, processing, done, error, permissionDenied }

class VoiceProvider extends ChangeNotifier {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();

  VoiceStatus _status = VoiceStatus.idle;
  String _liveTranscription = '';
  String _statusMessage = '';
  String _lastError = '';
  String? _itemContextName; // pre-seeded item name when mic tapped on a list item
  bool _isInitialized = false;

  VoiceStatus get status => _status;
  String get liveTranscription => _liveTranscription;
  String get statusMessage => _statusMessage;
  String get lastError => _lastError;
  String? get itemContextName => _itemContextName;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isProcessing => _status == VoiceStatus.processing;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.initialize();
    final available = await _speech.initialize();
    _isInitialized = true;
    if (!available) {
      _status = VoiceStatus.permissionDenied;
      _statusMessage = 'Microphone permission required';
      notifyListeners();
    }
  }

  Future<void> startListening(GroceryProvider groceryProvider,
      {String? itemContextName}) async {
    if (!_isInitialized) await initialize();
    if (_status == VoiceStatus.listening) return;

    _liveTranscription = '';
    _statusMessage = 'Listening…';
    _lastError = '';
    _itemContextName = itemContextName;
    _status = VoiceStatus.listening;
    notifyListeners();

    await _speech.startListening(
      localeId: 'en_IN',
      onResult: (text, isFinal) {
        _liveTranscription = text;
        notifyListeners();

        if (isFinal && text.isNotEmpty) {
          _processCommand(text, groceryProvider);
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_status == VoiceStatus.listening && _liveTranscription.isEmpty) {
            _status = VoiceStatus.idle;
            _statusMessage = '';
            notifyListeners();
          }
        }
      },
      onError: (error) {
        if (error != 'error_speech_timeout' && error != 'error_no_match') {
          _lastError = error;
          _status = VoiceStatus.error;
          _statusMessage = 'Error: $error';
          notifyListeners();
        } else {
          _status = VoiceStatus.idle;
          _statusMessage = '';
          notifyListeners();
        }
      },
    );
  }

  Future<void> stopListening(GroceryProvider groceryProvider) async {
    await _speech.stopListening();
    if (_liveTranscription.isNotEmpty) {
      await _processCommand(_liveTranscription, groceryProvider);
    } else {
      _status = VoiceStatus.idle;
      _statusMessage = '';
      notifyListeners();
    }
  }

  Future<void> cancelListening() async {
    await _speech.cancelListening();
    _status = VoiceStatus.idle;
    _liveTranscription = '';
    _statusMessage = '';
    _itemContextName = null;
    notifyListeners();
  }

  Future<void> _processCommand(
    String text,
    GroceryProvider groceryProvider,
  ) async {
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
        feedback = 'Sorry, I didn\'t understand that. Try: "add 2 kg tomatoes"';
        break;
    }

    _status = VoiceStatus.done;
    _statusMessage = feedback ?? 'Done';
    notifyListeners();

    // Speak confirmation
    if (feedback != null) {
      await _tts.speak(feedback);
    }

    // Auto-reset to idle after a short delay
    await Future.delayed(const Duration(seconds: 2));
    if (_status == VoiceStatus.done) {
      _status = VoiceStatus.idle;
      _liveTranscription = '';
      _statusMessage = '';
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _speech.dispose();
    _tts.dispose();
    super.dispose();
  }
}
