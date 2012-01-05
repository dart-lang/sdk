// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackListWrappingImplementation extends DOMWrapperBase implements TextTrackList {
  _TextTrackListWrappingImplementation() : super() {}

  static create__TextTrackListWrappingImplementation() native {
    return new _TextTrackListWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  EventListener get onaddtrack() { return _get_onaddtrack(this); }
  static EventListener _get_onaddtrack(var _this) native;

  void set onaddtrack(EventListener value) { _set_onaddtrack(this, value); }
  static void _set_onaddtrack(var _this, EventListener value) native;

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

  TextTrack item(int index) {
    return _item(this, index);
  }
  static TextTrack _item(receiver, index) native;

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

  String get typeName() { return "TextTrackList"; }
}
