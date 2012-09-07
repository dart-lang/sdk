// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SVGSVGElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGSVGElement {
  SVGSVGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory SVGSVGElementWrappingImplementation() {
    var el = new SVGElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }

  String get contentScriptType { return _ptr.contentScriptType; }

  void set contentScriptType(String value) { _ptr.contentScriptType = value; }

  String get contentStyleType { return _ptr.contentStyleType; }

  void set contentStyleType(String value) { _ptr.contentStyleType = value; }

  num get currentScale { return _ptr.currentScale; }

  void set currentScale(num value) { _ptr.currentScale = value; }

  SVGPoint get currentTranslate { return LevelDom.wrapSVGPoint(_ptr.currentTranslate); }

  SVGAnimatedLength get height { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  num get pixelUnitToMillimeterX { return _ptr.pixelUnitToMillimeterX; }

  num get pixelUnitToMillimeterY { return _ptr.pixelUnitToMillimeterY; }

  num get screenPixelToMillimeterX { return _ptr.screenPixelToMillimeterX; }

  num get screenPixelToMillimeterY { return _ptr.screenPixelToMillimeterY; }

  bool get useCurrentView { return _ptr.useCurrentView; }

  void set useCurrentView(bool value) { _ptr.useCurrentView = value; }

  SVGRect get viewport { return LevelDom.wrapSVGRect(_ptr.viewport); }

  SVGAnimatedLength get width { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  bool animationsPaused() {
    return _ptr.animationsPaused();
  }

  bool checkEnclosure(SVGElement element, SVGRect rect) {
    return _ptr.checkEnclosure(LevelDom.unwrap(element), LevelDom.unwrap(rect));
  }

  bool checkIntersection(SVGElement element, SVGRect rect) {
    return _ptr.checkIntersection(LevelDom.unwrap(element), LevelDom.unwrap(rect));
  }

  SVGAngle createSVGAngle() {
    return LevelDom.wrapSVGAngle(_ptr.createSVGAngle());
  }

  SVGLength createSVGLength() {
    return LevelDom.wrapSVGLength(_ptr.createSVGLength());
  }

  SVGMatrix createSVGMatrix() {
    return LevelDom.wrapSVGMatrix(_ptr.createSVGMatrix());
  }

  SVGNumber createSVGNumber() {
    return LevelDom.wrapSVGNumber(_ptr.createSVGNumber());
  }

  SVGPoint createSVGPoint() {
    return LevelDom.wrapSVGPoint(_ptr.createSVGPoint());
  }

  SVGRect createSVGRect() {
    return LevelDom.wrapSVGRect(_ptr.createSVGRect());
  }

  SVGTransform createSVGTransform() {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransform());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransformFromMatrix(LevelDom.unwrap(matrix)));
  }

  void deselectAll() {
    _ptr.deselectAll();
    return;
  }

  void forceRedraw() {
    _ptr.forceRedraw();
    return;
  }

  num getCurrentTime() {
    return _ptr.getCurrentTime();
  }

  Element getElementById(String elementId) {
    return LevelDom.wrapElement(_ptr.getElementById(elementId));
  }

  ElementList getEnclosureList(SVGRect rect, SVGElement referenceElement) {
    return LevelDom.wrapElementList(_ptr.getEnclosureList(LevelDom.unwrap(rect), LevelDom.unwrap(referenceElement)));
  }

  ElementList getIntersectionList(SVGRect rect, SVGElement referenceElement) {
    return LevelDom.wrapElementList(_ptr.getIntersectionList(LevelDom.unwrap(rect), LevelDom.unwrap(referenceElement)));
  }

  void pauseAnimations() {
    _ptr.pauseAnimations();
    return;
  }

  void setCurrentTime(num seconds) {
    _ptr.setCurrentTime(seconds);
    return;
  }

  int suspendRedraw(int maxWaitMilliseconds) {
    return _ptr.suspendRedraw(maxWaitMilliseconds);
  }

  void unpauseAnimations() {
    _ptr.unpauseAnimations();
    return;
  }

  void unsuspendRedraw(int suspendHandleId) {
    _ptr.unsuspendRedraw(suspendHandleId);
    return;
  }

  void unsuspendRedrawAll() {
    _ptr.unsuspendRedrawAll();
    return;
  }

  // From SVGTests

  SVGStringList get requiredExtensions { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGLocatable

  SVGElement get farthestViewportElement { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }

  // From SVGZoomAndPan

  int get zoomAndPan { return _ptr.zoomAndPan; }

  void set zoomAndPan(int value) { _ptr.zoomAndPan = value; }
}
