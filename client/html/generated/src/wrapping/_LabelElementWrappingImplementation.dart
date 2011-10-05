// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LabelElementWrappingImplementation extends ElementWrappingImplementation implements LabelElement {
  LabelElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  Element get control() { return LevelDom.wrapElement(_ptr.control); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get htmlFor() { return _ptr.htmlFor; }

  void set htmlFor(String value) { _ptr.htmlFor = value; }

  String get typeName() { return "LabelElement"; }
}
