// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _RectWrappingImplementation extends DOMWrapperBase implements Rect {
  _RectWrappingImplementation() : super() {}

  static create__RectWrappingImplementation() native {
    return new _RectWrappingImplementation();
  }

  CSSPrimitiveValue get bottom() { return _get_bottom(this); }
  static CSSPrimitiveValue _get_bottom(var _this) native;

  CSSPrimitiveValue get left() { return _get_left(this); }
  static CSSPrimitiveValue _get_left(var _this) native;

  CSSPrimitiveValue get right() { return _get_right(this); }
  static CSSPrimitiveValue _get_right(var _this) native;

  CSSPrimitiveValue get top() { return _get_top(this); }
  static CSSPrimitiveValue _get_top(var _this) native;

  String get typeName() { return "Rect"; }
}
