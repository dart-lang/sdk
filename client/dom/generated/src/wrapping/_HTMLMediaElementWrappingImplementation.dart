// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLMediaElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLMediaElement {
  _HTMLMediaElementWrappingImplementation() : super() {}

  static create__HTMLMediaElementWrappingImplementation() native {
    return new _HTMLMediaElementWrappingImplementation();
  }

  bool get autoplay() { return _get_autoplay(this); }
  static bool _get_autoplay(var _this) native;

  void set autoplay(bool value) { _set_autoplay(this, value); }
  static void _set_autoplay(var _this, bool value) native;

  TimeRanges get buffered() { return _get_buffered(this); }
  static TimeRanges _get_buffered(var _this) native;

  bool get controls() { return _get_controls(this); }
  static bool _get_controls(var _this) native;

  void set controls(bool value) { _set_controls(this, value); }
  static void _set_controls(var _this, bool value) native;

  String get currentSrc() { return _get_currentSrc(this); }
  static String _get_currentSrc(var _this) native;

  num get currentTime() { return _get_currentTime(this); }
  static num _get_currentTime(var _this) native;

  void set currentTime(num value) { _set_currentTime(this, value); }
  static void _set_currentTime(var _this, num value) native;

  bool get defaultMuted() { return _get_defaultMuted(this); }
  static bool _get_defaultMuted(var _this) native;

  void set defaultMuted(bool value) { _set_defaultMuted(this, value); }
  static void _set_defaultMuted(var _this, bool value) native;

  num get defaultPlaybackRate() { return _get_defaultPlaybackRate(this); }
  static num _get_defaultPlaybackRate(var _this) native;

  void set defaultPlaybackRate(num value) { _set_defaultPlaybackRate(this, value); }
  static void _set_defaultPlaybackRate(var _this, num value) native;

  num get duration() { return _get_duration(this); }
  static num _get_duration(var _this) native;

  bool get ended() { return _get_ended(this); }
  static bool _get_ended(var _this) native;

  MediaError get error() { return _get_error(this); }
  static MediaError _get_error(var _this) native;

  num get initialTime() { return _get_initialTime(this); }
  static num _get_initialTime(var _this) native;

  bool get loop() { return _get_loop(this); }
  static bool _get_loop(var _this) native;

  void set loop(bool value) { _set_loop(this, value); }
  static void _set_loop(var _this, bool value) native;

  bool get muted() { return _get_muted(this); }
  static bool _get_muted(var _this) native;

  void set muted(bool value) { _set_muted(this, value); }
  static void _set_muted(var _this, bool value) native;

  int get networkState() { return _get_networkState(this); }
  static int _get_networkState(var _this) native;

  bool get paused() { return _get_paused(this); }
  static bool _get_paused(var _this) native;

  num get playbackRate() { return _get_playbackRate(this); }
  static num _get_playbackRate(var _this) native;

  void set playbackRate(num value) { _set_playbackRate(this, value); }
  static void _set_playbackRate(var _this, num value) native;

  TimeRanges get played() { return _get_played(this); }
  static TimeRanges _get_played(var _this) native;

  String get preload() { return _get_preload(this); }
  static String _get_preload(var _this) native;

  void set preload(String value) { _set_preload(this, value); }
  static void _set_preload(var _this, String value) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  TimeRanges get seekable() { return _get_seekable(this); }
  static TimeRanges _get_seekable(var _this) native;

  bool get seeking() { return _get_seeking(this); }
  static bool _get_seeking(var _this) native;

  String get src() { return _get_src(this); }
  static String _get_src(var _this) native;

  void set src(String value) { _set_src(this, value); }
  static void _set_src(var _this, String value) native;

  num get startTime() { return _get_startTime(this); }
  static num _get_startTime(var _this) native;

  num get volume() { return _get_volume(this); }
  static num _get_volume(var _this) native;

  void set volume(num value) { _set_volume(this, value); }
  static void _set_volume(var _this, num value) native;

  int get webkitAudioDecodedByteCount() { return _get_webkitAudioDecodedByteCount(this); }
  static int _get_webkitAudioDecodedByteCount(var _this) native;

  bool get webkitClosedCaptionsVisible() { return _get_webkitClosedCaptionsVisible(this); }
  static bool _get_webkitClosedCaptionsVisible(var _this) native;

  void set webkitClosedCaptionsVisible(bool value) { _set_webkitClosedCaptionsVisible(this, value); }
  static void _set_webkitClosedCaptionsVisible(var _this, bool value) native;

  bool get webkitHasClosedCaptions() { return _get_webkitHasClosedCaptions(this); }
  static bool _get_webkitHasClosedCaptions(var _this) native;

  bool get webkitPreservesPitch() { return _get_webkitPreservesPitch(this); }
  static bool _get_webkitPreservesPitch(var _this) native;

  void set webkitPreservesPitch(bool value) { _set_webkitPreservesPitch(this, value); }
  static void _set_webkitPreservesPitch(var _this, bool value) native;

  int get webkitVideoDecodedByteCount() { return _get_webkitVideoDecodedByteCount(this); }
  static int _get_webkitVideoDecodedByteCount(var _this) native;

  String canPlayType(String type) {
    return _canPlayType(this, type);
  }
  static String _canPlayType(receiver, type) native;

  void load() {
    _load(this);
    return;
  }
  static void _load(receiver) native;

  void pause() {
    _pause(this);
    return;
  }
  static void _pause(receiver) native;

  void play() {
    _play(this);
    return;
  }
  static void _play(receiver) native;

  String get typeName() { return "HTMLMediaElement"; }
}
