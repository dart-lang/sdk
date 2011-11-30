// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGLengthWrappingImplementation extends DOMWrapperBase implements SVGLength {
  _SVGLengthWrappingImplementation() : super() {}

  static create__SVGLengthWrappingImplementation() native {
    return new _SVGLengthWrappingImplementation();
  }

  int get unitType() { return _get_unitType(this); }
  static int _get_unitType(var _this) native;

  num get value() { return _get_value(this); }
  static num _get_value(var _this) native;

  void set value(num value) { _set_value(this, value); }
  static void _set_value(var _this, num value) native;

  String get valueAsString() { return _get_valueAsString(this); }
  static String _get_valueAsString(var _this) native;

  void set valueAsString(String value) { _set_valueAsString(this, value); }
  static void _set_valueAsString(var _this, String value) native;

  num get valueInSpecifiedUnits() { return _get_valueInSpecifiedUnits(this); }
  static num _get_valueInSpecifiedUnits(var _this) native;

  void set valueInSpecifiedUnits(num value) { _set_valueInSpecifiedUnits(this, value); }
  static void _set_valueInSpecifiedUnits(var _this, num value) native;

  void convertToSpecifiedUnits(int unitType) {
    _convertToSpecifiedUnits(this, unitType);
    return;
  }
  static void _convertToSpecifiedUnits(receiver, unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) {
    _newValueSpecifiedUnits(this, unitType, valueInSpecifiedUnits);
    return;
  }
  static void _newValueSpecifiedUnits(receiver, unitType, valueInSpecifiedUnits) native;

  String get typeName() { return "SVGLength"; }
}
