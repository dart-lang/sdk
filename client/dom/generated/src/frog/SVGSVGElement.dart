
class SVGSVGElement extends SVGElement native "SVGSVGElement" {

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  SVGPoint currentTranslate;

  SVGAnimatedLength height;

  num pixelUnitToMillimeterX;

  num pixelUnitToMillimeterY;

  num screenPixelToMillimeterX;

  num screenPixelToMillimeterY;

  bool useCurrentView;

  SVGRect viewport;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  bool animationsPaused() native;

  bool checkEnclosure(SVGElement element, SVGRect rect) native;

  bool checkIntersection(SVGElement element, SVGRect rect) native;

  SVGAngle createSVGAngle() native;

  SVGLength createSVGLength() native;

  SVGMatrix createSVGMatrix() native;

  SVGNumber createSVGNumber() native;

  SVGPoint createSVGPoint() native;

  SVGRect createSVGRect() native;

  SVGTransform createSVGTransform() native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  Element getElementById(String elementId) native;

  NodeList getEnclosureList(SVGRect rect, SVGElement referenceElement) native;

  NodeList getIntersectionList(SVGRect rect, SVGElement referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}
