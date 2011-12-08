// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LinkElementWrappingImplementation extends ElementWrappingImplementation implements LinkElement {
  LinkElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get hreflang() { return _ptr.hreflang; }

  void set hreflang(String value) { _ptr.hreflang = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get rel() { return _ptr.rel; }

  void set rel(String value) { _ptr.rel = value; }

  String get rev() { return _ptr.rev; }

  void set rev(String value) { _ptr.rev = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  DOMSettableTokenList get sizes() { return LevelDom.wrapDOMSettableTokenList(_ptr.sizes); }

  void set sizes(DOMSettableTokenList value) { _ptr.sizes = LevelDom.unwrap(value); }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
