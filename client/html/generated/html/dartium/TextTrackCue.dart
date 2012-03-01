
class _TextTrackCueImpl extends _DOMTypeBase implements TextTrackCue {
  _TextTrackCueImpl._wrap(ptr) : super._wrap(ptr);

  String get alignment() => _wrap(_ptr.alignment);

  void set alignment(String value) { _ptr.alignment = _unwrap(value); }

  String get direction() => _wrap(_ptr.direction);

  void set direction(String value) { _ptr.direction = _unwrap(value); }

  num get endTime() => _wrap(_ptr.endTime);

  void set endTime(num value) { _ptr.endTime = _unwrap(value); }

  String get id() => _wrap(_ptr.id);

  void set id(String value) { _ptr.id = _unwrap(value); }

  int get linePosition() => _wrap(_ptr.linePosition);

  void set linePosition(int value) { _ptr.linePosition = _unwrap(value); }

  EventListener get onenter() => _wrap(_ptr.onenter);

  void set onenter(EventListener value) { _ptr.onenter = _unwrap(value); }

  EventListener get onexit() => _wrap(_ptr.onexit);

  void set onexit(EventListener value) { _ptr.onexit = _unwrap(value); }

  bool get pauseOnExit() => _wrap(_ptr.pauseOnExit);

  void set pauseOnExit(bool value) { _ptr.pauseOnExit = _unwrap(value); }

  int get size() => _wrap(_ptr.size);

  void set size(int value) { _ptr.size = _unwrap(value); }

  bool get snapToLines() => _wrap(_ptr.snapToLines);

  void set snapToLines(bool value) { _ptr.snapToLines = _unwrap(value); }

  num get startTime() => _wrap(_ptr.startTime);

  void set startTime(num value) { _ptr.startTime = _unwrap(value); }

  String get text() => _wrap(_ptr.text);

  void set text(String value) { _ptr.text = _unwrap(value); }

  int get textPosition() => _wrap(_ptr.textPosition);

  void set textPosition(int value) { _ptr.textPosition = _unwrap(value); }

  TextTrack get track() => _wrap(_ptr.track);

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

  DocumentFragment getCueAsHTML() {
    return _wrap(_ptr.getCueAsHTML());
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
