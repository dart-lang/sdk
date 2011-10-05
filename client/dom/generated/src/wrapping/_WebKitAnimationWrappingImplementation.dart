// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitAnimationWrappingImplementation extends DOMWrapperBase implements WebKitAnimation {
  _WebKitAnimationWrappingImplementation() : super() {}

  static create__WebKitAnimationWrappingImplementation() native {
    return new _WebKitAnimationWrappingImplementation();
  }

  num get delay() { return _get__WebKitAnimation_delay(this); }
  static num _get__WebKitAnimation_delay(var _this) native;

  int get direction() { return _get__WebKitAnimation_direction(this); }
  static int _get__WebKitAnimation_direction(var _this) native;

  num get duration() { return _get__WebKitAnimation_duration(this); }
  static num _get__WebKitAnimation_duration(var _this) native;

  num get elapsedTime() { return _get__WebKitAnimation_elapsedTime(this); }
  static num _get__WebKitAnimation_elapsedTime(var _this) native;

  void set elapsedTime(num value) { _set__WebKitAnimation_elapsedTime(this, value); }
  static void _set__WebKitAnimation_elapsedTime(var _this, num value) native;

  bool get ended() { return _get__WebKitAnimation_ended(this); }
  static bool _get__WebKitAnimation_ended(var _this) native;

  int get fillMode() { return _get__WebKitAnimation_fillMode(this); }
  static int _get__WebKitAnimation_fillMode(var _this) native;

  int get iterationCount() { return _get__WebKitAnimation_iterationCount(this); }
  static int _get__WebKitAnimation_iterationCount(var _this) native;

  String get name() { return _get__WebKitAnimation_name(this); }
  static String _get__WebKitAnimation_name(var _this) native;

  bool get paused() { return _get__WebKitAnimation_paused(this); }
  static bool _get__WebKitAnimation_paused(var _this) native;

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

  String get typeName() { return "WebKitAnimation"; }
}
