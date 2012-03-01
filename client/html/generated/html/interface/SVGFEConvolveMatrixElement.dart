// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEConvolveMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final SVGAnimatedNumber bias;

  final SVGAnimatedNumber divisor;

  final SVGAnimatedEnumeration edgeMode;

  final SVGAnimatedString in1;

  final SVGAnimatedNumberList kernelMatrix;

  final SVGAnimatedNumber kernelUnitLengthX;

  final SVGAnimatedNumber kernelUnitLengthY;

  final SVGAnimatedInteger orderX;

  final SVGAnimatedInteger orderY;

  final SVGAnimatedBoolean preserveAlpha;

  final SVGAnimatedInteger targetX;

  final SVGAnimatedInteger targetY;
}
