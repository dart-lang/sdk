// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WheelEventWrappingImplementation extends _UIEventWrappingImplementation implements WheelEvent {
  _WheelEventWrappingImplementation() : super() {}

  static create__WheelEventWrappingImplementation() native {
    return new _WheelEventWrappingImplementation();
  }

  bool get altKey() { return _get__WheelEvent_altKey(this); }
  static bool _get__WheelEvent_altKey(var _this) native;

  int get clientX() { return _get__WheelEvent_clientX(this); }
  static int _get__WheelEvent_clientX(var _this) native;

  int get clientY() { return _get__WheelEvent_clientY(this); }
  static int _get__WheelEvent_clientY(var _this) native;

  bool get ctrlKey() { return _get__WheelEvent_ctrlKey(this); }
  static bool _get__WheelEvent_ctrlKey(var _this) native;

  bool get metaKey() { return _get__WheelEvent_metaKey(this); }
  static bool _get__WheelEvent_metaKey(var _this) native;

  int get offsetX() { return _get__WheelEvent_offsetX(this); }
  static int _get__WheelEvent_offsetX(var _this) native;

  int get offsetY() { return _get__WheelEvent_offsetY(this); }
  static int _get__WheelEvent_offsetY(var _this) native;

  int get screenX() { return _get__WheelEvent_screenX(this); }
  static int _get__WheelEvent_screenX(var _this) native;

  int get screenY() { return _get__WheelEvent_screenY(this); }
  static int _get__WheelEvent_screenY(var _this) native;

  bool get shiftKey() { return _get__WheelEvent_shiftKey(this); }
  static bool _get__WheelEvent_shiftKey(var _this) native;

  int get wheelDelta() { return _get__WheelEvent_wheelDelta(this); }
  static int _get__WheelEvent_wheelDelta(var _this) native;

  int get wheelDeltaX() { return _get__WheelEvent_wheelDeltaX(this); }
  static int _get__WheelEvent_wheelDeltaX(var _this) native;

  int get wheelDeltaY() { return _get__WheelEvent_wheelDeltaY(this); }
  static int _get__WheelEvent_wheelDeltaY(var _this) native;

  int get x() { return _get__WheelEvent_x(this); }
  static int _get__WheelEvent_x(var _this) native;

  int get y() { return _get__WheelEvent_y(this); }
  static int _get__WheelEvent_y(var _this) native;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _initWebKitWheelEvent(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return;
  }
  static void _initWebKitWheelEvent(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;

  String get typeName() { return "WheelEvent"; }
}
