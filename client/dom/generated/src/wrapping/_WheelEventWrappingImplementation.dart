// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WheelEventWrappingImplementation extends _UIEventWrappingImplementation implements WheelEvent {
  _WheelEventWrappingImplementation() : super() {}

  static create__WheelEventWrappingImplementation() native {
    return new _WheelEventWrappingImplementation();
  }

  bool get altKey() { return _get_altKey(this); }
  static bool _get_altKey(var _this) native;

  int get clientX() { return _get_clientX(this); }
  static int _get_clientX(var _this) native;

  int get clientY() { return _get_clientY(this); }
  static int _get_clientY(var _this) native;

  bool get ctrlKey() { return _get_ctrlKey(this); }
  static bool _get_ctrlKey(var _this) native;

  bool get metaKey() { return _get_metaKey(this); }
  static bool _get_metaKey(var _this) native;

  int get offsetX() { return _get_offsetX(this); }
  static int _get_offsetX(var _this) native;

  int get offsetY() { return _get_offsetY(this); }
  static int _get_offsetY(var _this) native;

  int get screenX() { return _get_screenX(this); }
  static int _get_screenX(var _this) native;

  int get screenY() { return _get_screenY(this); }
  static int _get_screenY(var _this) native;

  bool get shiftKey() { return _get_shiftKey(this); }
  static bool _get_shiftKey(var _this) native;

  bool get webkitDirectionInvertedFromDevice() { return _get_webkitDirectionInvertedFromDevice(this); }
  static bool _get_webkitDirectionInvertedFromDevice(var _this) native;

  int get wheelDelta() { return _get_wheelDelta(this); }
  static int _get_wheelDelta(var _this) native;

  int get wheelDeltaX() { return _get_wheelDeltaX(this); }
  static int _get_wheelDeltaX(var _this) native;

  int get wheelDeltaY() { return _get_wheelDeltaY(this); }
  static int _get_wheelDeltaY(var _this) native;

  int get x() { return _get_x(this); }
  static int _get_x(var _this) native;

  int get y() { return _get_y(this); }
  static int _get_y(var _this) native;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _initWebKitWheelEvent(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return;
  }
  static void _initWebKitWheelEvent(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;

  String get typeName() { return "WheelEvent"; }
}
