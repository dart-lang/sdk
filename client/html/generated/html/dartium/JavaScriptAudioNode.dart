
class _JavaScriptAudioNodeImpl extends _AudioNodeImpl implements JavaScriptAudioNode {
  _JavaScriptAudioNodeImpl._wrap(ptr) : super._wrap(ptr);

  int get bufferSize() => _wrap(_ptr.bufferSize);

  EventListener get onaudioprocess() => _wrap(_ptr.onaudioprocess);

  void set onaudioprocess(EventListener value) { _ptr.onaudioprocess = _unwrap(value); }
}
