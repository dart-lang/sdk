// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLength {

  static final int SVG_LENGTHTYPE_CM = 6;

  static final int SVG_LENGTHTYPE_EMS = 3;

  static final int SVG_LENGTHTYPE_EXS = 4;

  static final int SVG_LENGTHTYPE_IN = 8;

  static final int SVG_LENGTHTYPE_MM = 7;

  static final int SVG_LENGTHTYPE_NUMBER = 1;

  static final int SVG_LENGTHTYPE_PC = 10;

  static final int SVG_LENGTHTYPE_PERCENTAGE = 2;

  static final int SVG_LENGTHTYPE_PT = 9;

  static final int SVG_LENGTHTYPE_PX = 5;

  static final int SVG_LENGTHTYPE_UNKNOWN = 0;

  final int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
