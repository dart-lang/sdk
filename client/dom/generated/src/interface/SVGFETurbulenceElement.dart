// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFETurbulenceElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  final SVGAnimatedNumber baseFrequencyX;

  final SVGAnimatedNumber baseFrequencyY;

  final SVGAnimatedInteger numOctaves;

  final SVGAnimatedNumber seed;

  final SVGAnimatedEnumeration stitchTiles;

  final SVGAnimatedEnumeration type;
}
