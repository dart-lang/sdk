// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaControllerWrappingImplementation extends DOMWrapperBase implements MediaController {
  _MediaControllerWrappingImplementation() : super() {}

  static create__MediaControllerWrappingImplementation() native {
    return new _MediaControllerWrappingImplementation();
  }

  TimeRanges get buffered() { return _get_buffered(this); }
  static TimeRanges _get_buffered(var _this) native;

  num get currentTime() { return _get_currentTime(this); }
  static num _get_currentTime(var _this) native;

  void set currentTime(num value) { _set_currentTime(this, value); }
  static void _set_currentTime(var _this, num value) native;

  num get defaultPlaybackRate() { return _get_defaultPlaybackRate(this); }
  static num _get_defaultPlaybackRate(var _this) native;

  void set defaultPlaybackRate(num value) { _set_defaultPlaybackRate(this, value); }
  static void _set_defaultPlaybackRate(var _this, num value) native;

  num get duration() { return _get_duration(this); }
  static num _get_duration(var _this) native;

  bool get muted() { return _get_muted(this); }
  static bool _get_muted(var _this) native;

  void set muted(bool value) { _set_muted(this, value); }
  static void _set_muted(var _this, bool value) native;

  bool get paused() { return _get_paused(this); }
  static bool _get_paused(var _this) native;

  num get playbackRate() { return _get_playbackRate(this); }
  static num _get_playbackRate(var _this) native;

  void set playbackRate(num value) { _set_playbackRate(this, value); }
  static void _set_playbackRate(var _this, num value) native;

  TimeRanges get played() { return _get_played(this); }
  static TimeRanges _get_played(var _this) native;

  TimeRanges get seekable() { return _get_seekable(this); }
  static TimeRanges _get_seekable(var _this) native;

  num get volume() { return _get_volume(this); }
  static num _get_volume(var _this) native;

  void set volume(num value) { _set_volume(this, value); }
  static void _set_volume(var _this, num value) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener(this, type, listener);
      return;
    } else {
      _addEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener(receiver, type, listener) native;
  static void _addEventListener_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

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

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener(this, type, listener);
      return;
    } else {
      _removeEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener(receiver, type, listener) native;
  static void _removeEventListener_2(receiver, type, listener, useCapture) native;

  String get typeName() { return "MediaController"; }
}
