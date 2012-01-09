// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackCueWrappingImplementation extends DOMWrapperBase implements TextTrackCue {
  _TextTrackCueWrappingImplementation() : super() {}

  static create__TextTrackCueWrappingImplementation() native {
    return new _TextTrackCueWrappingImplementation();
  }

  String get alignment() { return _get_alignment(this); }
  static String _get_alignment(var _this) native;

  String get direction() { return _get_direction(this); }
  static String _get_direction(var _this) native;

  num get endTime() { return _get_endTime(this); }
  static num _get_endTime(var _this) native;

  String get id() { return _get_id(this); }
  static String _get_id(var _this) native;

  int get linePosition() { return _get_linePosition(this); }
  static int _get_linePosition(var _this) native;

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

  int get size() { return _get_size(this); }
  static int _get_size(var _this) native;

  bool get snapToLines() { return _get_snapToLines(this); }
  static bool _get_snapToLines(var _this) native;

  num get startTime() { return _get_startTime(this); }
  static num _get_startTime(var _this) native;

  int get textPosition() { return _get_textPosition(this); }
  static int _get_textPosition(var _this) native;

  TextTrack get track() { return _get_track(this); }
  static TextTrack _get_track(var _this) native;

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

  String getCueAsSource() {
    return _getCueAsSource(this);
  }
  static String _getCueAsSource(receiver) native;

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
