// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface SVGSVGElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGLocatable, SVGFitToViewBox, SVGZoomAndPan
    default SVGSVGElementWrappingImplementation {

  SVGSVGElement();

  String get contentScriptType;

  void set contentScriptType(String value);

  String get contentStyleType;

  void set contentStyleType(String value);

  num get currentScale;

  void set currentScale(num value);

  SVGPoint get currentTranslate;

  SVGAnimatedLength get height;

  num get pixelUnitToMillimeterX;

  num get pixelUnitToMillimeterY;

  num get screenPixelToMillimeterX;

  num get screenPixelToMillimeterY;

  bool get useCurrentView;

  void set useCurrentView(bool value);

  SVGRect get viewport;

  SVGAnimatedLength get width;

  SVGAnimatedLength get x;

  SVGAnimatedLength get y;

  bool animationsPaused();

  bool checkEnclosure(SVGElement element, SVGRect rect);

  bool checkIntersection(SVGElement element, SVGRect rect);

  SVGAngle createSVGAngle();

  SVGLength createSVGLength();

  SVGMatrix createSVGMatrix();

  SVGNumber createSVGNumber();

  SVGPoint createSVGPoint();

  SVGRect createSVGRect();

  SVGTransform createSVGTransform();

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix);

  void deselectAll();

  void forceRedraw();

  num getCurrentTime();

  Element getElementById(String elementId);

  ElementList getEnclosureList(SVGRect rect, SVGElement referenceElement);

  ElementList getIntersectionList(SVGRect rect, SVGElement referenceElement);

  void pauseAnimations();

  void setCurrentTime(num seconds);

  int suspendRedraw(int maxWaitMilliseconds);

  void unpauseAnimations();

  void unsuspendRedraw(int suspendHandleId);

  void unsuspendRedrawAll();
}
