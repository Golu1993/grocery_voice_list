enum SmoothSpeechState {
  idle,
  starting,
  listening,
  stopping,
  unavailable,
  error,
}

extension SmoothSpeechStateX on SmoothSpeechState {
  bool get isActive =>
      this == SmoothSpeechState.starting ||
      this == SmoothSpeechState.listening ||
      this == SmoothSpeechState.stopping;
}
