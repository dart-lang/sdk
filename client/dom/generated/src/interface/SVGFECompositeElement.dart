// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFECompositeElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  SVGAnimatedString get in1();

  SVGAnimatedString get in2();

  SVGAnimatedNumber get k1();

  SVGAnimatedNumber get k2();

  SVGAnimatedNumber get k3();

  SVGAnimatedNumber get k4();

  SVGAnimatedEnumeration get operator();
}
