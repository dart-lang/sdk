// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProgressElementWrappingImplementation extends ElementWrappingImplementation implements ProgressElement {
  ProgressElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get position() { return _ptr.position; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  String get typeName() { return "ProgressElement"; }
}
