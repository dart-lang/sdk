
class _TextTrackListImpl extends _DOMTypeBase implements TextTrackList {
  _TextTrackListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  EventListener get onaddtrack() => _wrap(_ptr.onaddtrack);

  void set onaddtrack(EventListener value) { _ptr.onaddtrack = _unwrap(value); }

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

  TextTrack item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
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
