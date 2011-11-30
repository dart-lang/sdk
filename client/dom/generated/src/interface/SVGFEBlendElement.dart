// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEBlendElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  SVGAnimatedString get in1();

  SVGAnimatedString get in2();

  SVGAnimatedEnumeration get mode();
}
