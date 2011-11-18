// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TouchWrappingImplementation extends DOMWrapperBase implements Touch {
  _TouchWrappingImplementation() : super() {}

  static create__TouchWrappingImplementation() native {
    return new _TouchWrappingImplementation();
  }

  int get clientX() { return _get_clientX(this); }
  static int _get_clientX(var _this) native;

  int get clientY() { return _get_clientY(this); }
  static int _get_clientY(var _this) native;

  int get identifier() { return _get_identifier(this); }
  static int _get_identifier(var _this) native;

  int get pageX() { return _get_pageX(this); }
  static int _get_pageX(var _this) native;

  int get pageY() { return _get_pageY(this); }
  static int _get_pageY(var _this) native;

  int get screenX() { return _get_screenX(this); }
  static int _get_screenX(var _this) native;

  int get screenY() { return _get_screenY(this); }
  static int _get_screenY(var _this) native;

  EventTarget get target() { return _get_target(this); }
  static EventTarget _get_target(var _this) native;

  num get webkitForce() { return _get_webkitForce(this); }
  static num _get_webkitForce(var _this) native;

  int get webkitRadiusX() { return _get_webkitRadiusX(this); }
  static int _get_webkitRadiusX(var _this) native;

  int get webkitRadiusY() { return _get_webkitRadiusY(this); }
  static int _get_webkitRadiusY(var _this) native;

  num get webkitRotationAngle() { return _get_webkitRotationAngle(this); }
  static num _get_webkitRotationAngle(var _this) native;

  String get typeName() { return "Touch"; }
}
