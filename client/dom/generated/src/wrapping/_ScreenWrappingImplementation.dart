// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ScreenWrappingImplementation extends DOMWrapperBase implements Screen {
  _ScreenWrappingImplementation() : super() {}

  static create__ScreenWrappingImplementation() native {
    return new _ScreenWrappingImplementation();
  }

  int get availHeight() { return _get__Screen_availHeight(this); }
  static int _get__Screen_availHeight(var _this) native;

  int get availLeft() { return _get__Screen_availLeft(this); }
  static int _get__Screen_availLeft(var _this) native;

  int get availTop() { return _get__Screen_availTop(this); }
  static int _get__Screen_availTop(var _this) native;

  int get availWidth() { return _get__Screen_availWidth(this); }
  static int _get__Screen_availWidth(var _this) native;

  int get colorDepth() { return _get__Screen_colorDepth(this); }
  static int _get__Screen_colorDepth(var _this) native;

  int get height() { return _get__Screen_height(this); }
  static int _get__Screen_height(var _this) native;

  int get pixelDepth() { return _get__Screen_pixelDepth(this); }
  static int _get__Screen_pixelDepth(var _this) native;

  int get width() { return _get__Screen_width(this); }
  static int _get__Screen_width(var _this) native;

  String get typeName() { return "Screen"; }
}
