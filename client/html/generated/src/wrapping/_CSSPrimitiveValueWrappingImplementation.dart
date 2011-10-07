// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPrimitiveValueWrappingImplementation extends CSSValueWrappingImplementation implements CSSPrimitiveValue {
  CSSPrimitiveValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get primitiveType() { return _ptr.primitiveType; }

  Counter getCounterValue() {
    return LevelDom.wrapCounter(_ptr.getCounterValue());
  }

  num getFloatValue(int unitType) {
    return _ptr.getFloatValue(unitType);
  }

  RGBColor getRGBColorValue() {
    return LevelDom.wrapRGBColor(_ptr.getRGBColorValue());
  }

  Rect getRectValue() {
    return LevelDom.wrapRect(_ptr.getRectValue());
  }

  String getStringValue() {
    return _ptr.getStringValue();
  }

  void setFloatValue(int unitType, num floatValue) {
    _ptr.setFloatValue(unitType, floatValue);
    return;
  }

  void setStringValue(int stringType, String stringValue) {
    _ptr.setStringValue(stringType, stringValue);
    return;
  }
}
