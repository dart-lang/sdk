// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframesRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframesRule {
  CSSKeyframesRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  void deleteRule(String key) {
    _ptr.deleteRule(key);
    return;
  }

  CSSKeyframeRule findRule(String key) {
    return LevelDom.wrapCSSKeyframeRule(_ptr.findRule(key));
  }

  void insertRule(String rule) {
    _ptr.insertRule(rule);
    return;
  }

  String get typeName() { return "CSSKeyframesRule"; }
}
