// Stub AI service — plug in Gemma, Gemini, or Claude here when ready.
// When an AI model is available, override parseCommand() to return richer
// ParsedCommand objects for ambiguous voice input.

import '../services/voice_parser.dart';

abstract class AIService {
  Future<ParsedCommand?> parseCommand(String rawText);
  Future<String?> suggestItems(List<String> existingItems);
  bool get isAvailable;
}

class NoopAIService implements AIService {
  @override
  bool get isAvailable => false;

  @override
  Future<ParsedCommand?> parseCommand(String rawText) async => null;

  @override
  Future<String?> suggestItems(List<String> existingItems) async => null;
}

// Example skeleton for a future Gemini/Claude integration:
//
// class GeminiAIService implements AIService {
//   final String apiKey;
//   GeminiAIService(this.apiKey);
//
//   @override
//   bool get isAvailable => apiKey.isNotEmpty;
//
//   @override
//   Future<ParsedCommand?> parseCommand(String rawText) async {
//     // Call Gemini API with a structured prompt to parse the command
//     // Return a ParsedCommand on success, null on failure
//     return null;
//   }
//
//   @override
//   Future<String?> suggestItems(List<String> existingItems) async {
//     // Return AI-suggested complementary grocery items
//     return null;
//   }
// }
