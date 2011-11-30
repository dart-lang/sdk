// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGPathSegList get animatedNormalizedPathSegList();

  SVGPathSegList get animatedPathSegList();

  SVGPathSegList get normalizedPathSegList();

  SVGAnimatedNumber get pathLength();

  SVGPathSegList get pathSegList();

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag);

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag);

  SVGPathSegClosePath createSVGPathSegClosePath();

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2);

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2);

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2);

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2);

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1);

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1);

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y);

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y);

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y);

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x);

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x);

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y);

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y);

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y);

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y);

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y);

  int getPathSegAtLength(num distance);

  SVGPoint getPointAtLength(num distance);

  num getTotalLength();
}
