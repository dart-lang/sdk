// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAngle {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int get unitType();

  num get value();

  void set value(num value);

  String get valueAsString();

  void set valueAsString(String value);

  num get valueInSpecifiedUnits();

  void set valueInSpecifiedUnits(num value);

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
