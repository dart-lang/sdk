
class _SpeechInputResultImpl extends _DOMTypeBase implements SpeechInputResult {
  _SpeechInputResultImpl._wrap(ptr) : super._wrap(ptr);

  num get confidence() => _wrap(_ptr.confidence);

  String get utterance() => _wrap(_ptr.utterance);
}
