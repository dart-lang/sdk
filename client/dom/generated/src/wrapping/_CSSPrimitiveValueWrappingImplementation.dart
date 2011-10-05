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

  num getFloatValue(int unitType = null) {
    if (unitType === null) {
      return _getFloatValue(this);
    } else {
      return _getFloatValue_2(this, unitType);
    }
  }
  static num _getFloatValue(receiver) native;
  static num _getFloatValue_2(receiver, unitType) native;

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

  void setFloatValue(int unitType = null, num floatValue = null) {
    if (unitType === null) {
      if (floatValue === null) {
        _setFloatValue(this);
        return;
      }
    } else {
      if (floatValue === null) {
        _setFloatValue_2(this, unitType);
        return;
      } else {
        _setFloatValue_3(this, unitType, floatValue);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setFloatValue(receiver) native;
  static void _setFloatValue_2(receiver, unitType) native;
  static void _setFloatValue_3(receiver, unitType, floatValue) native;

  void setStringValue(int stringType = null, String stringValue = null) {
    if (stringType === null) {
      if (stringValue === null) {
        _setStringValue(this);
        return;
      }
    } else {
      if (stringValue === null) {
        _setStringValue_2(this, stringType);
        return;
      } else {
        _setStringValue_3(this, stringType, stringValue);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setStringValue(receiver) native;
  static void _setStringValue_2(receiver, stringType) native;
  static void _setStringValue_3(receiver, stringType, stringValue) native;

  String get typeName() { return "CSSPrimitiveValue"; }
}
