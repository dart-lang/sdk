// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEConvolveMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber get bias();

  SVGAnimatedNumber get divisor();

  SVGAnimatedEnumeration get edgeMode();

  SVGAnimatedString get in1();

  SVGAnimatedNumberList get kernelMatrix();

  SVGAnimatedNumber get kernelUnitLengthX();

  SVGAnimatedNumber get kernelUnitLengthY();

  SVGAnimatedInteger get orderX();

  SVGAnimatedInteger get orderY();

  SVGAnimatedBoolean get preserveAlpha();

  SVGAnimatedInteger get targetX();

  SVGAnimatedInteger get targetY();
}
