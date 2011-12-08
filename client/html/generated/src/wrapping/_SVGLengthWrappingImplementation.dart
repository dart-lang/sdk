// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLengthWrappingImplementation extends DOMWrapperBase implements SVGLength {
  SVGLengthWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get unitType() { return _ptr.unitType; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  String get valueAsString() { return _ptr.valueAsString; }

  void set valueAsString(String value) { _ptr.valueAsString = value; }

  num get valueInSpecifiedUnits() { return _ptr.valueInSpecifiedUnits; }

  void set valueInSpecifiedUnits(num value) { _ptr.valueInSpecifiedUnits = value; }

  void convertToSpecifiedUnits(int unitType) {
    _ptr.convertToSpecifiedUnits(unitType);
    return;
  }

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) {
    _ptr.newValueSpecifiedUnits(unitType, valueInSpecifiedUnits);
    return;
  }
}
