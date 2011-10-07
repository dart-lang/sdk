// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMediaRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSMediaRule {
  CSSMediaRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }
}
