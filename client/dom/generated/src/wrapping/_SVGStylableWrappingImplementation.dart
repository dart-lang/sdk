// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGStylableWrappingImplementation extends DOMWrapperBase implements SVGStylable {
  _SVGStylableWrappingImplementation() : super() {}

  static create__SVGStylableWrappingImplementation() native {
    return new _SVGStylableWrappingImplementation();
  }

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style(this); }
  static CSSStyleDeclaration _get_style(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGStylable"; }
}
