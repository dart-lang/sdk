
class _TextTrackCueImpl extends _DOMTypeBase implements TextTrackCue {
  _TextTrackCueImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  num get endTime() => _wrap(_ptr.endTime);

  void set endTime(num value) { _ptr.endTime = _unwrap(value); }

  String get id() => _wrap(_ptr.id);

  void set id(String value) { _ptr.id = _unwrap(value); }

  int get line() => _wrap(_ptr.line);

  void set line(int value) { _ptr.line = _unwrap(value); }

  EventListener get onenter() => _wrap(_ptr.onenter);

  void set onenter(EventListener value) { _ptr.onenter = _unwrap(value); }

  EventListener get onexit() => _wrap(_ptr.onexit);

  void set onexit(EventListener value) { _ptr.onexit = _unwrap(value); }

  bool get pauseOnExit() => _wrap(_ptr.pauseOnExit);

  void set pauseOnExit(bool value) { _ptr.pauseOnExit = _unwrap(value); }

  int get position() => _wrap(_ptr.position);

  void set position(int value) { _ptr.position = _unwrap(value); }

  int get size() => _wrap(_ptr.size);

  void set size(int value) { _ptr.size = _unwrap(value); }

  bool get snapToLines() => _wrap(_ptr.snapToLines);

  void set snapToLines(bool value) { _ptr.snapToLines = _unwrap(value); }

  num get startTime() => _wrap(_ptr.startTime);

  void set startTime(num value) { _ptr.startTime = _unwrap(value); }

  String get text() => _wrap(_ptr.text);

  void set text(String value) { _ptr.text = _unwrap(value); }

  TextTrack get track() => _wrap(_ptr.track);

  String get vertical() => _wrap(_ptr.vertical);

  void set vertical(String value) { _ptr.vertical = _unwrap(value); }

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
