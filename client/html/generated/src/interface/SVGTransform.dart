// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransform {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  num get angle();

  SVGMatrix get matrix();

  int get type();

  void setMatrix(SVGMatrix matrix);

  void setRotate(num angle, num cx, num cy);

  void setScale(num sx, num sy);

  void setSkewX(num angle);

  void setSkewY(num angle);

  void setTranslate(num tx, num ty);
}
