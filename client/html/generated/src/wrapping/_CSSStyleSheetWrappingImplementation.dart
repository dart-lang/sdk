// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSStyleSheetWrappingImplementation extends StyleSheetWrappingImplementation implements CSSStyleSheet {
  CSSStyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  CSSRule get ownerRule() { return LevelDom.wrapCSSRule(_ptr.ownerRule); }

  CSSRuleList get rules() { return LevelDom.wrapCSSRuleList(_ptr.rules); }

  int addRule(String selector, String style, int index) {
    return _ptr.addRule(selector, style, index);
  }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }

  void removeRule(int index) {
    _ptr.removeRule(index);
    return;
  }

  String get typeName() { return "CSSStyleSheet"; }
}
