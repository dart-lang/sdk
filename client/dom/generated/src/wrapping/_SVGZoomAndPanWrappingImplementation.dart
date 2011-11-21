// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGZoomAndPanWrappingImplementation extends DOMWrapperBase implements SVGZoomAndPan {
  _SVGZoomAndPanWrappingImplementation() : super() {}

  static create__SVGZoomAndPanWrappingImplementation() native {
    return new _SVGZoomAndPanWrappingImplementation();
  }

  int get zoomAndPan() { return _get_zoomAndPan(this); }
  static int _get_zoomAndPan(var _this) native;

  void set zoomAndPan(int value) { _set_zoomAndPan(this, value); }
  static void _set_zoomAndPan(var _this, int value) native;

  String get typeName() { return "SVGZoomAndPan"; }
}
