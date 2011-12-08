// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGColor extends CSSValue {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  int get colorType();

  RGBColor get rgbColor();

  void setColor(int colorType, String rgbColor, String iccColor);

  void setRGBColor(String rgbColor);

  void setRGBColorICCColor(String rgbColor, String iccColor);
}
