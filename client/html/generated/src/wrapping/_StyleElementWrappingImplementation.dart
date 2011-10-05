// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleElementWrappingImplementation extends ElementWrappingImplementation implements StyleElement {
  StyleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get typeName() { return "StyleElement"; }
}
