// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframeRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframeRule {
  CSSKeyframeRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyText() { return _ptr.keyText; }

  void set keyText(String value) { _ptr.keyText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  String get typeName() { return "CSSKeyframeRule"; }
}
