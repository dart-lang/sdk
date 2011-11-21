// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPaint extends SVGColor {

  static final int SVG_PAINTTYPE_CURRENTCOLOR = 102;

  static final int SVG_PAINTTYPE_NONE = 101;

  static final int SVG_PAINTTYPE_RGBCOLOR = 1;

  static final int SVG_PAINTTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_PAINTTYPE_UNKNOWN = 0;

  static final int SVG_PAINTTYPE_URI = 107;

  static final int SVG_PAINTTYPE_URI_CURRENTCOLOR = 104;

  static final int SVG_PAINTTYPE_URI_NONE = 103;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR = 105;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR_ICCCOLOR = 106;

  int get paintType();

  String get uri();

  void setPaint(int paintType, String uri, String rgbColor, String iccColor);

  void setUri(String uri);
}
