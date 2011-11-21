// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMorphologyElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  SVGAnimatedString get in1();

  SVGAnimatedEnumeration get operator();

  SVGAnimatedNumber get radiusX();

  SVGAnimatedNumber get radiusY();

  void setRadius(num radiusX, num radiusY);
}
