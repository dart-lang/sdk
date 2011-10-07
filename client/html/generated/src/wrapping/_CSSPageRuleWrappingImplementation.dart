// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPageRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSPageRule {
  CSSPageRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get selectorText() { return _ptr.selectorText; }

  void set selectorText(String value) { _ptr.selectorText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
