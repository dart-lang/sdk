
class _TextTrackImpl extends _DOMTypeBase implements TextTrack {
  _TextTrackImpl._wrap(ptr) : super._wrap(ptr);

  TextTrackCueList get activeCues() => _wrap(_ptr.activeCues);

  TextTrackCueList get cues() => _wrap(_ptr.cues);

  String get kind() => _wrap(_ptr.kind);

  String get label() => _wrap(_ptr.label);

  String get language() => _wrap(_ptr.language);

  int get mode() => _wrap(_ptr.mode);

  void set mode(int value) { _ptr.mode = _unwrap(value); }

  EventListener get oncuechange() => _wrap(_ptr.oncuechange);

  void set oncuechange(EventListener value) { _ptr.oncuechange = _unwrap(value); }

  void addCue(TextTrackCue cue) {
    _ptr.addCue(_unwrap(cue));
    return;
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  void removeCue(TextTrackCue cue) {
    _ptr.removeCue(_unwrap(cue));
    return;
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }
}
