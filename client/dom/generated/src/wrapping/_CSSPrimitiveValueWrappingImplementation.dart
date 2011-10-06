// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSPrimitiveValueWrappingImplementation extends _CSSValueWrappingImplementation implements CSSPrimitiveValue {
  _CSSPrimitiveValueWrappingImplementation() : super() {}

  static create__CSSPrimitiveValueWrappingImplementation() native {
    return new _CSSPrimitiveValueWrappingImplementation();
  }

  int get primitiveType() { return _get__CSSPrimitiveValue_primitiveType(this); }
  static int _get__CSSPrimitiveValue_primitiveType(var _this) native;

  Counter getCounterValue() {
    return _getCounterValue(this);
  }
  static Counter _getCounterValue(receiver) native;

  num getFloatValue(int unitType) {
    return _getFloatValue(this, unitType);
  }
  static num _getFloatValue(receiver, unitType) native;

  RGBColor getRGBColorValue() {
    return _getRGBColorValue(this);
  }
  static RGBColor _getRGBColorValue(receiver) native;

  Rect getRectValue() {
    return _getRectValue(this);
  }
  static Rect _getRectValue(receiver) native;

  String getStringValue() {
    return _getStringValue(this);
  }
  static String _getStringValue(receiver) native;

  void setFloatValue(int unitType, num floatValue) {
    _setFloatValue(this, unitType, floatValue);
    return;
  }
  static void _setFloatValue(receiver, unitType, floatValue) native;

  void setStringValue(int stringType, String stringValue) {
    _setStringValue(this, stringType, stringValue);
    return;
  }
  static void _setStringValue(receiver, stringType, stringValue) native;

  String get typeName() { return "CSSPrimitiveValue"; }
}
