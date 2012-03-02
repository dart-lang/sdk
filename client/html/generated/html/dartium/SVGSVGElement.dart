
class _SVGSVGElementImpl extends _SVGElementImpl implements SVGSVGElement {
  _SVGSVGElementImpl._wrap(ptr) : super._wrap(ptr);

  String get contentScriptType() => _wrap(_ptr.contentScriptType);

  void set contentScriptType(String value) { _ptr.contentScriptType = _unwrap(value); }

  String get contentStyleType() => _wrap(_ptr.contentStyleType);

  void set contentStyleType(String value) { _ptr.contentStyleType = _unwrap(value); }

  num get currentScale() => _wrap(_ptr.currentScale);

  void set currentScale(num value) { _ptr.currentScale = _unwrap(value); }

  SVGPoint get currentTranslate() => _wrap(_ptr.currentTranslate);

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  num get pixelUnitToMillimeterX() => _wrap(_ptr.pixelUnitToMillimeterX);

  num get pixelUnitToMillimeterY() => _wrap(_ptr.pixelUnitToMillimeterY);

  num get screenPixelToMillimeterX() => _wrap(_ptr.screenPixelToMillimeterX);

  num get screenPixelToMillimeterY() => _wrap(_ptr.screenPixelToMillimeterY);

  bool get useCurrentView() => _wrap(_ptr.useCurrentView);

  void set useCurrentView(bool value) { _ptr.useCurrentView = _unwrap(value); }

  SVGRect get viewport() => _wrap(_ptr.viewport);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  bool animationsPaused() {
    return _wrap(_ptr.animationsPaused());
  }

  bool checkEnclosure(SVGElement element, SVGRect rect) {
    return _wrap(_ptr.checkEnclosure(_unwrap(element), _unwrap(rect)));
  }

  bool checkIntersection(SVGElement element, SVGRect rect) {
    return _wrap(_ptr.checkIntersection(_unwrap(element), _unwrap(rect)));
  }

  SVGAngle createSVGAngle() {
    return _wrap(_ptr.createSVGAngle());
  }

  SVGLength createSVGLength() {
    return _wrap(_ptr.createSVGLength());
  }

  SVGMatrix createSVGMatrix() {
    return _wrap(_ptr.createSVGMatrix());
  }

  SVGNumber createSVGNumber() {
    return _wrap(_ptr.createSVGNumber());
  }

  SVGPoint createSVGPoint() {
    return _wrap(_ptr.createSVGPoint());
  }

  SVGRect createSVGRect() {
    return _wrap(_ptr.createSVGRect());
  }

  SVGTransform createSVGTransform() {
    return _wrap(_ptr.createSVGTransform());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return _wrap(_ptr.createSVGTransformFromMatrix(_unwrap(matrix)));
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
    return _wrap(_ptr.getCurrentTime());
  }

  Element getElementById(String elementId) {
    return _wrap(_ptr.getElementById(_unwrap(elementId)));
  }

  NodeList getEnclosureList(SVGRect rect, SVGElement referenceElement) {
    return _wrap(_ptr.getEnclosureList(_unwrap(rect), _unwrap(referenceElement)));
  }

  NodeList getIntersectionList(SVGRect rect, SVGElement referenceElement) {
    return _wrap(_ptr.getIntersectionList(_unwrap(rect), _unwrap(referenceElement)));
  }

  void pauseAnimations() {
    _ptr.pauseAnimations();
    return;
  }

  void setCurrentTime(num seconds) {
    _ptr.setCurrentTime(_unwrap(seconds));
    return;
  }

  int suspendRedraw(int maxWaitMilliseconds) {
    return _wrap(_ptr.suspendRedraw(_unwrap(maxWaitMilliseconds)));
  }

  void unpauseAnimations() {
    _ptr.unpauseAnimations();
    return;
  }

  void unsuspendRedraw(int suspendHandleId) {
    _ptr.unsuspendRedraw(_unwrap(suspendHandleId));
    return;
  }

  void unsuspendRedrawAll() {
    _ptr.unsuspendRedrawAll();
    return;
  }

  // From SVGTests

  SVGStringList get requiredExtensions() => _wrap(_ptr.requiredExtensions);

  SVGStringList get requiredFeatures() => _wrap(_ptr.requiredFeatures);

  SVGStringList get systemLanguage() => _wrap(_ptr.systemLanguage);

  bool hasExtension(String extension) {
    return _wrap(_ptr.hasExtension(_unwrap(extension)));
  }

  // From SVGLangSpace

  String get xmllang() => _wrap(_ptr.xmllang);

  void set xmllang(String value) { _ptr.xmllang = _unwrap(value); }

  String get xmlspace() => _wrap(_ptr.xmlspace);

  void set xmlspace(String value) { _ptr.xmlspace = _unwrap(value); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }

  // From SVGLocatable

  SVGElement get farthestViewportElement() => _wrap(_ptr.farthestViewportElement);

  SVGElement get nearestViewportElement() => _wrap(_ptr.nearestViewportElement);

  SVGRect getBBox() {
    return _wrap(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return _wrap(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return _wrap(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return _wrap(_ptr.getTransformToElement(_unwrap(element)));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);

  // From SVGZoomAndPan

  int get zoomAndPan() => _wrap(_ptr.zoomAndPan);

  void set zoomAndPan(int value) { _ptr.zoomAndPan = _unwrap(value); }
}
