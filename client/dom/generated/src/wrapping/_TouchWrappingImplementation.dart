// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TouchWrappingImplementation extends DOMWrapperBase implements Touch {
  _TouchWrappingImplementation() : super() {}

  static create__TouchWrappingImplementation() native {
    return new _TouchWrappingImplementation();
  }

  int get clientX() { return _get__Touch_clientX(this); }
  static int _get__Touch_clientX(var _this) native;

  int get clientY() { return _get__Touch_clientY(this); }
  static int _get__Touch_clientY(var _this) native;

  int get identifier() { return _get__Touch_identifier(this); }
  static int _get__Touch_identifier(var _this) native;

  int get pageX() { return _get__Touch_pageX(this); }
  static int _get__Touch_pageX(var _this) native;

  int get pageY() { return _get__Touch_pageY(this); }
  static int _get__Touch_pageY(var _this) native;

  int get screenX() { return _get__Touch_screenX(this); }
  static int _get__Touch_screenX(var _this) native;

  int get screenY() { return _get__Touch_screenY(this); }
  static int _get__Touch_screenY(var _this) native;

  EventTarget get target() { return _get__Touch_target(this); }
  static EventTarget _get__Touch_target(var _this) native;

  num get webkitForce() { return _get__Touch_webkitForce(this); }
  static num _get__Touch_webkitForce(var _this) native;

  int get webkitRadiusX() { return _get__Touch_webkitRadiusX(this); }
  static int _get__Touch_webkitRadiusX(var _this) native;

  int get webkitRadiusY() { return _get__Touch_webkitRadiusY(this); }
  static int _get__Touch_webkitRadiusY(var _this) native;

  num get webkitRotationAngle() { return _get__Touch_webkitRotationAngle(this); }
  static num _get__Touch_webkitRotationAngle(var _this) native;

  String get typeName() { return "Touch"; }
}
