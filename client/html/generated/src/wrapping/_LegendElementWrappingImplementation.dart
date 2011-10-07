// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LegendElementWrappingImplementation extends ElementWrappingImplementation implements LegendElement {
  LegendElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }
}
