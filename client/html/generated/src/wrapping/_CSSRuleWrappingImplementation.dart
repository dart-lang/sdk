// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSRuleWrappingImplementation extends DOMWrapperBase implements CSSRule {
  CSSRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSStyleSheet get parentStyleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.parentStyleSheet); }

  int get type() { return _ptr.type; }
}
