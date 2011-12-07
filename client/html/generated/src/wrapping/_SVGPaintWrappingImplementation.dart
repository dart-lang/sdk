// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPaintWrappingImplementation extends SVGColorWrappingImplementation implements SVGPaint {
  SVGPaintWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get paintType() { return _ptr.paintType; }

  String get uri() { return _ptr.uri; }

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) {
    _ptr.setPaint(paintType, uri, rgbColor, iccColor);
    return;
  }

  void setUri(String uri) {
    _ptr.setUri(uri);
    return;
  }
}
