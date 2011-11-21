// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGSVGElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGSVGElement {
  _SVGSVGElementWrappingImplementation() : super() {}

  static create__SVGSVGElementWrappingImplementation() native {
    return new _SVGSVGElementWrappingImplementation();
  }

  String get contentScriptType() { return _get_contentScriptType(this); }
  static String _get_contentScriptType(var _this) native;

  void set contentScriptType(String value) { _set_contentScriptType(this, value); }
  static void _set_contentScriptType(var _this, String value) native;

  String get contentStyleType() { return _get_contentStyleType(this); }
  static String _get_contentStyleType(var _this) native;

  void set contentStyleType(String value) { _set_contentStyleType(this, value); }
  static void _set_contentStyleType(var _this, String value) native;

  num get currentScale() { return _get_currentScale(this); }
  static num _get_currentScale(var _this) native;

  void set currentScale(num value) { _set_currentScale(this, value); }
  static void _set_currentScale(var _this, num value) native;

  SVGPoint get currentTranslate() { return _get_currentTranslate(this); }
  static SVGPoint _get_currentTranslate(var _this) native;

  SVGAnimatedLength get height() { return _get_height(this); }
  static SVGAnimatedLength _get_height(var _this) native;

  num get pixelUnitToMillimeterX() { return _get_pixelUnitToMillimeterX(this); }
  static num _get_pixelUnitToMillimeterX(var _this) native;

  num get pixelUnitToMillimeterY() { return _get_pixelUnitToMillimeterY(this); }
  static num _get_pixelUnitToMillimeterY(var _this) native;

  num get screenPixelToMillimeterX() { return _get_screenPixelToMillimeterX(this); }
  static num _get_screenPixelToMillimeterX(var _this) native;

  num get screenPixelToMillimeterY() { return _get_screenPixelToMillimeterY(this); }
  static num _get_screenPixelToMillimeterY(var _this) native;

  bool get useCurrentView() { return _get_useCurrentView(this); }
  static bool _get_useCurrentView(var _this) native;

  void set useCurrentView(bool value) { _set_useCurrentView(this, value); }
  static void _set_useCurrentView(var _this, bool value) native;

  SVGRect get viewport() { return _get_viewport(this); }
  static SVGRect _get_viewport(var _this) native;

  SVGAnimatedLength get width() { return _get_width(this); }
  static SVGAnimatedLength _get_width(var _this) native;

  SVGAnimatedLength get x() { return _get_x(this); }
  static SVGAnimatedLength _get_x(var _this) native;

  SVGAnimatedLength get y() { return _get_y(this); }
  static SVGAnimatedLength _get_y(var _this) native;

  bool animationsPaused() {
    return _animationsPaused(this);
  }
  static bool _animationsPaused(receiver) native;

  bool checkEnclosure(SVGElement element, SVGRect rect) {
    return _checkEnclosure(this, element, rect);
  }
  static bool _checkEnclosure(receiver, element, rect) native;

  bool checkIntersection(SVGElement element, SVGRect rect) {
    return _checkIntersection(this, element, rect);
  }
  static bool _checkIntersection(receiver, element, rect) native;

  SVGAngle createSVGAngle() {
    return _createSVGAngle(this);
  }
  static SVGAngle _createSVGAngle(receiver) native;

  SVGLength createSVGLength() {
    return _createSVGLength(this);
  }
  static SVGLength _createSVGLength(receiver) native;

  SVGMatrix createSVGMatrix() {
    return _createSVGMatrix(this);
  }
  static SVGMatrix _createSVGMatrix(receiver) native;

  SVGNumber createSVGNumber() {
    return _createSVGNumber(this);
  }
  static SVGNumber _createSVGNumber(receiver) native;

  SVGPoint createSVGPoint() {
    return _createSVGPoint(this);
  }
  static SVGPoint _createSVGPoint(receiver) native;

  SVGRect createSVGRect() {
    return _createSVGRect(this);
  }
  static SVGRect _createSVGRect(receiver) native;

  SVGTransform createSVGTransform() {
    return _createSVGTransform(this);
  }
  static SVGTransform _createSVGTransform(receiver) native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return _createSVGTransformFromMatrix(this, matrix);
  }
  static SVGTransform _createSVGTransformFromMatrix(receiver, matrix) native;

  void deselectAll() {
    _deselectAll(this);
    return;
  }
  static void _deselectAll(receiver) native;

  void forceRedraw() {
    _forceRedraw(this);
    return;
  }
  static void _forceRedraw(receiver) native;

  num getCurrentTime() {
    return _getCurrentTime(this);
  }
  static num _getCurrentTime(receiver) native;

  Element getElementById(String elementId) {
    return _getElementById(this, elementId);
  }
  static Element _getElementById(receiver, elementId) native;

  NodeList getEnclosureList(SVGRect rect, SVGElement referenceElement) {
    return _getEnclosureList(this, rect, referenceElement);
  }
  static NodeList _getEnclosureList(receiver, rect, referenceElement) native;

  NodeList getIntersectionList(SVGRect rect, SVGElement referenceElement) {
    return _getIntersectionList(this, rect, referenceElement);
  }
  static NodeList _getIntersectionList(receiver, rect, referenceElement) native;

  void pauseAnimations() {
    _pauseAnimations(this);
    return;
  }
  static void _pauseAnimations(receiver) native;

  void setCurrentTime(num seconds) {
    _setCurrentTime(this, seconds);
    return;
  }
  static void _setCurrentTime(receiver, seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) {
    return _suspendRedraw(this, maxWaitMilliseconds);
  }
  static int _suspendRedraw(receiver, maxWaitMilliseconds) native;

  void unpauseAnimations() {
    _unpauseAnimations(this);
    return;
  }
  static void _unpauseAnimations(receiver) native;

  void unsuspendRedraw(int suspendHandleId) {
    _unsuspendRedraw(this, suspendHandleId);
    return;
  }
  static void _unsuspendRedraw(receiver, suspendHandleId) native;

  void unsuspendRedrawAll() {
    _unsuspendRedrawAll(this);
    return;
  }
  static void _unsuspendRedrawAll(receiver) native;

  // From SVGTests

  SVGStringList get requiredExtensions() { return _get_requiredExtensions(this); }
  static SVGStringList _get_requiredExtensions(var _this) native;

  SVGStringList get requiredFeatures() { return _get_requiredFeatures(this); }
  static SVGStringList _get_requiredFeatures(var _this) native;

  SVGStringList get systemLanguage() { return _get_systemLanguage(this); }
  static SVGStringList _get_systemLanguage(var _this) native;

  bool hasExtension(String extension) {
    return _hasExtension(this, extension);
  }
  static bool _hasExtension(receiver, extension) native;

  // From SVGLangSpace

  String get xmllang() { return _get_xmllang(this); }
  static String _get_xmllang(var _this) native;

  void set xmllang(String value) { _set_xmllang(this, value); }
  static void _set_xmllang(var _this, String value) native;

  String get xmlspace() { return _get_xmlspace(this); }
  static String _get_xmlspace(var _this) native;

  void set xmlspace(String value) { _set_xmlspace(this, value); }
  static void _set_xmlspace(var _this, String value) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGSVGElement(this); }
  static CSSStyleDeclaration _get_style_SVGSVGElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return _get_farthestViewportElement(this); }
  static SVGElement _get_farthestViewportElement(var _this) native;

  SVGElement get nearestViewportElement() { return _get_nearestViewportElement(this); }
  static SVGElement _get_nearestViewportElement(var _this) native;

  SVGRect getBBox() {
    return _getBBox(this);
  }
  static SVGRect _getBBox(receiver) native;

  SVGMatrix getCTM() {
    return _getCTM(this);
  }
  static SVGMatrix _getCTM(receiver) native;

  SVGMatrix getScreenCTM() {
    return _getScreenCTM(this);
  }
  static SVGMatrix _getScreenCTM(receiver) native;

  SVGMatrix getTransformToElement(SVGElement element) {
    return _getTransformToElement(this, element);
  }
  static SVGMatrix _getTransformToElement(receiver, element) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return _get_preserveAspectRatio(this); }
  static SVGAnimatedPreserveAspectRatio _get_preserveAspectRatio(var _this) native;

  SVGAnimatedRect get viewBox() { return _get_viewBox(this); }
  static SVGAnimatedRect _get_viewBox(var _this) native;

  // From SVGZoomAndPan

  int get zoomAndPan() { return _get_zoomAndPan(this); }
  static int _get_zoomAndPan(var _this) native;

  void set zoomAndPan(int value) { _set_zoomAndPan(this, value); }
  static void _set_zoomAndPan(var _this, int value) native;

  String get typeName() { return "SVGSVGElement"; }
}
