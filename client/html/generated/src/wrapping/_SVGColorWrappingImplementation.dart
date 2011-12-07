// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGColorWrappingImplementation extends CSSValueWrappingImplementation implements SVGColor {
  SVGColorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get colorType() { return _ptr.colorType; }

  RGBColor get rgbColor() { return LevelDom.wrapRGBColor(_ptr.rgbColor); }

  void setColor(int colorType, String rgbColor, String iccColor) {
    _ptr.setColor(colorType, rgbColor, iccColor);
    return;
  }

  void setRGBColor(String rgbColor) {
    _ptr.setRGBColor(rgbColor);
    return;
  }

  void setRGBColorICCColor(String rgbColor, String iccColor) {
    _ptr.setRGBColorICCColor(rgbColor, iccColor);
    return;
  }
}
