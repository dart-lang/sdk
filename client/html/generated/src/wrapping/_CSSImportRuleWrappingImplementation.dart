// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSImportRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSImportRule {
  CSSImportRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  CSSStyleSheet get styleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.styleSheet); }

  String get typeName() { return "CSSImportRule"; }
}
