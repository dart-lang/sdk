// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MeterElementWrappingImplementation extends ElementWrappingImplementation implements MeterElement {
  MeterElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  num get high() { return _ptr.high; }

  void set high(num value) { _ptr.high = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get low() { return _ptr.low; }

  void set low(num value) { _ptr.low = value; }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get min() { return _ptr.min; }

  void set min(num value) { _ptr.min = value; }

  num get optimum() { return _ptr.optimum; }

  void set optimum(num value) { _ptr.optimum = value; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  String get typeName() { return "MeterElement"; }
}
