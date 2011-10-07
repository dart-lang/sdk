// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaElementWrappingImplementation extends ElementWrappingImplementation implements MediaElement {
  MediaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autoplay() { return _ptr.autoplay; }

  void set autoplay(bool value) { _ptr.autoplay = value; }

  TimeRanges get buffered() { return LevelDom.wrapTimeRanges(_ptr.buffered); }

  bool get controls() { return _ptr.controls; }

  void set controls(bool value) { _ptr.controls = value; }

  String get currentSrc() { return _ptr.currentSrc; }

  num get currentTime() { return _ptr.currentTime; }

  void set currentTime(num value) { _ptr.currentTime = value; }

  bool get defaultMuted() { return _ptr.defaultMuted; }

  void set defaultMuted(bool value) { _ptr.defaultMuted = value; }

  num get defaultPlaybackRate() { return _ptr.defaultPlaybackRate; }

  void set defaultPlaybackRate(num value) { _ptr.defaultPlaybackRate = value; }

  num get duration() { return _ptr.duration; }

  bool get ended() { return _ptr.ended; }

  MediaError get error() { return LevelDom.wrapMediaError(_ptr.error); }

  num get initialTime() { return _ptr.initialTime; }

  bool get loop() { return _ptr.loop; }

  void set loop(bool value) { _ptr.loop = value; }

  bool get muted() { return _ptr.muted; }

  void set muted(bool value) { _ptr.muted = value; }

  int get networkState() { return _ptr.networkState; }

  bool get paused() { return _ptr.paused; }

  num get playbackRate() { return _ptr.playbackRate; }

  void set playbackRate(num value) { _ptr.playbackRate = value; }

  TimeRanges get played() { return LevelDom.wrapTimeRanges(_ptr.played); }

  String get preload() { return _ptr.preload; }

  void set preload(String value) { _ptr.preload = value; }

  int get readyState() { return _ptr.readyState; }

  TimeRanges get seekable() { return LevelDom.wrapTimeRanges(_ptr.seekable); }

  bool get seeking() { return _ptr.seeking; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  num get startTime() { return _ptr.startTime; }

  num get volume() { return _ptr.volume; }

  void set volume(num value) { _ptr.volume = value; }

  int get webkitAudioDecodedByteCount() { return _ptr.webkitAudioDecodedByteCount; }

  bool get webkitClosedCaptionsVisible() { return _ptr.webkitClosedCaptionsVisible; }

  void set webkitClosedCaptionsVisible(bool value) { _ptr.webkitClosedCaptionsVisible = value; }

  bool get webkitHasClosedCaptions() { return _ptr.webkitHasClosedCaptions; }

  bool get webkitPreservesPitch() { return _ptr.webkitPreservesPitch; }

  void set webkitPreservesPitch(bool value) { _ptr.webkitPreservesPitch = value; }

  int get webkitVideoDecodedByteCount() { return _ptr.webkitVideoDecodedByteCount; }

  String canPlayType(String type) {
    return _ptr.canPlayType(type);
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
}
