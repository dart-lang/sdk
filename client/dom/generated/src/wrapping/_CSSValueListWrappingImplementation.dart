// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSValueListWrappingImplementation extends _CSSValueWrappingImplementation implements CSSValueList {
  _CSSValueListWrappingImplementation() : super() {}

  static create__CSSValueListWrappingImplementation() native {
    return new _CSSValueListWrappingImplementation();
  }

  int get length() { return _get__CSSValueList_length(this); }
  static int _get__CSSValueList_length(var _this) native;

  CSSValue item(int index = null) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static CSSValue _item(receiver) native;
  static CSSValue _item_2(receiver, index) native;

  String get typeName() { return "CSSValueList"; }
}
