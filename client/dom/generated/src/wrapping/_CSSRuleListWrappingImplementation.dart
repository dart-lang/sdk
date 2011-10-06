// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSRuleListWrappingImplementation extends DOMWrapperBase implements CSSRuleList {
  _CSSRuleListWrappingImplementation() : super() {}

  static create__CSSRuleListWrappingImplementation() native {
    return new _CSSRuleListWrappingImplementation();
  }

  int get length() { return _get__CSSRuleList_length(this); }
  static int _get__CSSRuleList_length(var _this) native;

  CSSRule item(int index) {
    return _item(this, index);
  }
  static CSSRule _item(receiver, index) native;

  String get typeName() { return "CSSRuleList"; }
}
