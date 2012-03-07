// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackCueWrappingImplementation extends DOMWrapperBase implements TextTrackCue {
  _TextTrackCueWrappingImplementation() : super() {}

  static create__TextTrackCueWrappingImplementation() native {
    return new _TextTrackCueWrappingImplementation();
  }

  String get align() { return _get_align(this); }
  static String _get_align(var _this) native;

  void set align(String value) { _set_align(this, value); }
  static void _set_align(var _this, String value) native;

  num get endTime() { return _get_endTime(this); }
  static num _get_endTime(var _this) native;

  void set endTime(num value) { _set_endTime(this, value); }
  static void _set_endTime(var _this, num value) native;

  String get id() { return _get_id(this); }
  static String _get_id(var _this) native;

  void set id(String value) { _set_id(this, value); }
  static void _set_id(var _this, String value) native;

  int get line() { return _get_line(this); }
  static int _get_line(var _this) native;

  void set line(int value) { _set_line(this, value); }
  static void _set_line(var _this, int value) native;

  EventListener get onenter() { return _get_onenter(this); }
  static EventListener _get_onenter(var _this) native;

  void set onenter(EventListener value) { _set_onenter(this, value); }
  static void _set_onenter(var _this, EventListener value) native;

  EventListener get onexit() { return _get_onexit(this); }
  static EventListener _get_onexit(var _this) native;

  void set onexit(EventListener value) { _set_onexit(this, value); }
  static void _set_onexit(var _this, EventListener value) native;

  bool get pauseOnExit() { return _get_pauseOnExit(this); }
  static bool _get_pauseOnExit(var _this) native;

  void set pauseOnExit(bool value) { _set_pauseOnExit(this, value); }
  static void _set_pauseOnExit(var _this, bool value) native;

  int get position() { return _get_position(this); }
  static int _get_position(var _this) native;

  void set position(int value) { _set_position(this, value); }
  static void _set_position(var _this, int value) native;

  int get size() { return _get_size(this); }
  static int _get_size(var _this) native;

  void set size(int value) { _set_size(this, value); }
  static void _set_size(var _this, int value) native;

  bool get snapToLines() { return _get_snapToLines(this); }
  static bool _get_snapToLines(var _this) native;

  void set snapToLines(bool value) { _set_snapToLines(this, value); }
  static void _set_snapToLines(var _this, bool value) native;

  num get startTime() { return _get_startTime(this); }
  static num _get_startTime(var _this) native;

  void set startTime(num value) { _set_startTime(this, value); }
  static void _set_startTime(var _this, num value) native;

  String get text() { return _get_text(this); }
  static String _get_text(var _this) native;

  void set text(String value) { _set_text(this, value); }
  static void _set_text(var _this, String value) native;

  TextTrack get track() { return _get_track(this); }
  static TextTrack _get_track(var _this) native;

  String get vertical() { return _get_vertical(this); }
  static String _get_vertical(var _this) native;

  void set vertical(String value) { _set_vertical(this, value); }
  static void _set_vertical(var _this, String value) native;

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

  DocumentFragment getCueAsHTML() {
    return _getCueAsHTML(this);
  }
  static DocumentFragment _getCueAsHTML(receiver) native;

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

  String get typeName() { return "TextTrackCue"; }
}
