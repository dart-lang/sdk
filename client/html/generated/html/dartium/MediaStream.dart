
class _MediaStreamImpl extends _DOMTypeBase implements MediaStream {
  _MediaStreamImpl._wrap(ptr) : super._wrap(ptr);

  MediaStreamTrackList get audioTracks() => _wrap(_ptr.audioTracks);

  String get label() => _wrap(_ptr.label);

  EventListener get onended() => _wrap(_ptr.onended);

  void set onended(EventListener value) { _ptr.onended = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  MediaStreamTrackList get videoTracks() => _wrap(_ptr.videoTracks);

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  bool dispatchEvent(Event event) {
    return _wrap(_ptr.dispatchEvent(_unwrap(event)));
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
