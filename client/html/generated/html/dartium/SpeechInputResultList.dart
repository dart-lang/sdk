
class _SpeechInputResultListImpl extends _DOMTypeBase implements SpeechInputResultList {
  _SpeechInputResultListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  SpeechInputResult item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
