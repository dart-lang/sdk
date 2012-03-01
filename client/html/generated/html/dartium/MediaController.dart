
class _MediaControllerImpl extends _DOMTypeBase implements MediaController {
  _MediaControllerImpl._wrap(ptr) : super._wrap(ptr);

  TimeRanges get buffered() => _wrap(_ptr.buffered);

  num get currentTime() => _wrap(_ptr.currentTime);

  void set currentTime(num value) { _ptr.currentTime = _unwrap(value); }

  num get defaultPlaybackRate() => _wrap(_ptr.defaultPlaybackRate);

  void set defaultPlaybackRate(num value) { _ptr.defaultPlaybackRate = _unwrap(value); }

  num get duration() => _wrap(_ptr.duration);

  bool get muted() => _wrap(_ptr.muted);

  void set muted(bool value) { _ptr.muted = _unwrap(value); }

  bool get paused() => _wrap(_ptr.paused);

  num get playbackRate() => _wrap(_ptr.playbackRate);

  void set playbackRate(num value) { _ptr.playbackRate = _unwrap(value); }

  TimeRanges get played() => _wrap(_ptr.played);

  TimeRanges get seekable() => _wrap(_ptr.seekable);

  num get volume() => _wrap(_ptr.volume);

  void set volume(num value) { _ptr.volume = _unwrap(value); }

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

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
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
