// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMarkerElement extends SVGElement, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLength get markerHeight();

  SVGAnimatedEnumeration get markerUnits();

  SVGAnimatedLength get markerWidth();

  SVGAnimatedAngle get orientAngle();

  SVGAnimatedEnumeration get orientType();

  SVGAnimatedLength get refX();

  SVGAnimatedLength get refY();

  void setOrientToAngle(SVGAngle angle);

  void setOrientToAuto();
}
