// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSPrimitiveValue extends CSSValue {

  static final int CSS_ATTR = 22;

  static final int CSS_CM = 6;

  static final int CSS_COUNTER = 23;

  static final int CSS_DEG = 11;

  static final int CSS_DIMENSION = 18;

  static final int CSS_EMS = 3;

  static final int CSS_EXS = 4;

  static final int CSS_GRAD = 13;

  static final int CSS_HZ = 16;

  static final int CSS_IDENT = 21;

  static final int CSS_IN = 8;

  static final int CSS_KHZ = 17;

  static final int CSS_MM = 7;

  static final int CSS_MS = 14;

  static final int CSS_NUMBER = 1;

  static final int CSS_PC = 10;

  static final int CSS_PERCENTAGE = 2;

  static final int CSS_PT = 9;

  static final int CSS_PX = 5;

  static final int CSS_RAD = 12;

  static final int CSS_RECT = 24;

  static final int CSS_RGBCOLOR = 25;

  static final int CSS_S = 15;

  static final int CSS_STRING = 19;

  static final int CSS_UNKNOWN = 0;

  static final int CSS_URI = 20;

  int get primitiveType();

  Counter getCounterValue();

  num getFloatValue(int unitType = null);

  RGBColor getRGBColorValue();

  Rect getRectValue();

  String getStringValue();

  void setFloatValue(int unitType = null, num floatValue = null);

  void setStringValue(int stringType = null, String stringValue = null);
}
