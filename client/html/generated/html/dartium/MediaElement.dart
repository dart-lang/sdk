
class _MediaElementImpl extends _ElementImpl implements MediaElement {
  _MediaElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get autoplay() => _wrap(_ptr.autoplay);

  void set autoplay(bool value) { _ptr.autoplay = _unwrap(value); }

  TimeRanges get buffered() => _wrap(_ptr.buffered);

  MediaController get controller() => _wrap(_ptr.controller);

  void set controller(MediaController value) { _ptr.controller = _unwrap(value); }

  bool get controls() => _wrap(_ptr.controls);

  void set controls(bool value) { _ptr.controls = _unwrap(value); }

  String get currentSrc() => _wrap(_ptr.currentSrc);

  num get currentTime() => _wrap(_ptr.currentTime);

  void set currentTime(num value) { _ptr.currentTime = _unwrap(value); }

  bool get defaultMuted() => _wrap(_ptr.defaultMuted);

  void set defaultMuted(bool value) { _ptr.defaultMuted = _unwrap(value); }

  num get defaultPlaybackRate() => _wrap(_ptr.defaultPlaybackRate);

  void set defaultPlaybackRate(num value) { _ptr.defaultPlaybackRate = _unwrap(value); }

  num get duration() => _wrap(_ptr.duration);

  bool get ended() => _wrap(_ptr.ended);

  MediaError get error() => _wrap(_ptr.error);

  num get initialTime() => _wrap(_ptr.initialTime);

  bool get loop() => _wrap(_ptr.loop);

  void set loop(bool value) { _ptr.loop = _unwrap(value); }

  String get mediaGroup() => _wrap(_ptr.mediaGroup);

  void set mediaGroup(String value) { _ptr.mediaGroup = _unwrap(value); }

  bool get muted() => _wrap(_ptr.muted);

  void set muted(bool value) { _ptr.muted = _unwrap(value); }

  int get networkState() => _wrap(_ptr.networkState);

  bool get paused() => _wrap(_ptr.paused);

  num get playbackRate() => _wrap(_ptr.playbackRate);

  void set playbackRate(num value) { _ptr.playbackRate = _unwrap(value); }

  TimeRanges get played() => _wrap(_ptr.played);

  String get preload() => _wrap(_ptr.preload);

  void set preload(String value) { _ptr.preload = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  TimeRanges get seekable() => _wrap(_ptr.seekable);

  bool get seeking() => _wrap(_ptr.seeking);

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  num get startTime() => _wrap(_ptr.startTime);

  TextTrackList get textTracks() => _wrap(_ptr.textTracks);

  num get volume() => _wrap(_ptr.volume);

  void set volume(num value) { _ptr.volume = _unwrap(value); }

  int get webkitAudioDecodedByteCount() => _wrap(_ptr.webkitAudioDecodedByteCount);

  bool get webkitClosedCaptionsVisible() => _wrap(_ptr.webkitClosedCaptionsVisible);

  void set webkitClosedCaptionsVisible(bool value) { _ptr.webkitClosedCaptionsVisible = _unwrap(value); }

  bool get webkitHasClosedCaptions() => _wrap(_ptr.webkitHasClosedCaptions);

  String get webkitMediaSourceURL() => _wrap(_ptr.webkitMediaSourceURL);

  bool get webkitPreservesPitch() => _wrap(_ptr.webkitPreservesPitch);

  void set webkitPreservesPitch(bool value) { _ptr.webkitPreservesPitch = _unwrap(value); }

  int get webkitSourceState() => _wrap(_ptr.webkitSourceState);

  int get webkitVideoDecodedByteCount() => _wrap(_ptr.webkitVideoDecodedByteCount);

  TextTrack addTextTrack(String kind, [String label = null, String language = null]) {
    if (label === null) {
      if (language === null) {
        return _wrap(_ptr.addTextTrack(_unwrap(kind)));
      }
    } else {
      if (language === null) {
        return _wrap(_ptr.addTextTrack(_unwrap(kind), _unwrap(label)));
      } else {
        return _wrap(_ptr.addTextTrack(_unwrap(kind), _unwrap(label), _unwrap(language)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  String canPlayType(String type) {
    return _wrap(_ptr.canPlayType(_unwrap(type)));
  }

  void load() {
    _ptr.load();
    return;
  }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }

  void webkitSourceAppend(Uint8Array data) {
    _ptr.webkitSourceAppend(_unwrap(data));
    return;
  }

  void webkitSourceEndOfStream(int status) {
    _ptr.webkitSourceEndOfStream(_unwrap(status));
    return;
  }
}
