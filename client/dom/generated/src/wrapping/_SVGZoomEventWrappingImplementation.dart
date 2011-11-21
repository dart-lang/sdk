// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGZoomEventWrappingImplementation extends _UIEventWrappingImplementation implements SVGZoomEvent {
  _SVGZoomEventWrappingImplementation() : super() {}

  static create__SVGZoomEventWrappingImplementation() native {
    return new _SVGZoomEventWrappingImplementation();
  }

  num get newScale() { return _get_newScale(this); }
  static num _get_newScale(var _this) native;

  SVGPoint get newTranslate() { return _get_newTranslate(this); }
  static SVGPoint _get_newTranslate(var _this) native;

  num get previousScale() { return _get_previousScale(this); }
  static num _get_previousScale(var _this) native;

  SVGPoint get previousTranslate() { return _get_previousTranslate(this); }
  static SVGPoint _get_previousTranslate(var _this) native;

  SVGRect get zoomRectScreen() { return _get_zoomRectScreen(this); }
  static SVGRect _get_zoomRectScreen(var _this) native;

  String get typeName() { return "SVGZoomEvent"; }
}
