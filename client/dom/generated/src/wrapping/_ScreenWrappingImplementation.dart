// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ScreenWrappingImplementation extends DOMWrapperBase implements Screen {
  _ScreenWrappingImplementation() : super() {}

  static create__ScreenWrappingImplementation() native {
    return new _ScreenWrappingImplementation();
  }

  int get availHeight() { return _get_availHeight(this); }
  static int _get_availHeight(var _this) native;

  int get availLeft() { return _get_availLeft(this); }
  static int _get_availLeft(var _this) native;

  int get availTop() { return _get_availTop(this); }
  static int _get_availTop(var _this) native;

  int get availWidth() { return _get_availWidth(this); }
  static int _get_availWidth(var _this) native;

  int get colorDepth() { return _get_colorDepth(this); }
  static int _get_colorDepth(var _this) native;

  int get height() { return _get_height(this); }
  static int _get_height(var _this) native;

  int get pixelDepth() { return _get_pixelDepth(this); }
  static int _get_pixelDepth(var _this) native;

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

  String get typeName() { return "Screen"; }
}
