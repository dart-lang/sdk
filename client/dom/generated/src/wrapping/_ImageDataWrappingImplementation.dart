// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ImageDataWrappingImplementation extends DOMWrapperBase implements ImageData {
  _ImageDataWrappingImplementation() : super() {}

  static create__ImageDataWrappingImplementation() native {
    return new _ImageDataWrappingImplementation();
  }

  CanvasPixelArray get data() { return _get_data(this); }
  static CanvasPixelArray _get_data(var _this) native;

  int get height() { return _get_height(this); }
  static int _get_height(var _this) native;

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

  String get typeName() { return "ImageData"; }
}
