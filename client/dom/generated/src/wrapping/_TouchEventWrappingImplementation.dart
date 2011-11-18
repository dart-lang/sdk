// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TouchEventWrappingImplementation extends _UIEventWrappingImplementation implements TouchEvent {
  _TouchEventWrappingImplementation() : super() {}

  static create__TouchEventWrappingImplementation() native {
    return new _TouchEventWrappingImplementation();
  }

  bool get altKey() { return _get_altKey(this); }
  static bool _get_altKey(var _this) native;

  TouchList get changedTouches() { return _get_changedTouches(this); }
  static TouchList _get_changedTouches(var _this) native;

  bool get ctrlKey() { return _get_ctrlKey(this); }
  static bool _get_ctrlKey(var _this) native;

  bool get metaKey() { return _get_metaKey(this); }
  static bool _get_metaKey(var _this) native;

  bool get shiftKey() { return _get_shiftKey(this); }
  static bool _get_shiftKey(var _this) native;

  TouchList get targetTouches() { return _get_targetTouches(this); }
  static TouchList _get_targetTouches(var _this) native;

  TouchList get touches() { return _get_touches(this); }
  static TouchList _get_touches(var _this) native;

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _initTouchEvent(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return;
  }
  static void _initTouchEvent(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;

  String get typeName() { return "TouchEvent"; }
}
