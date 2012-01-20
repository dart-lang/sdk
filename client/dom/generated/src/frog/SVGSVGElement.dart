
class SVGSVGElement extends SVGElement native "*SVGSVGElement" {

  String get contentScriptType() native "return this.contentScriptType;";

  void set contentScriptType(String value) native "this.contentScriptType = value;";

  String get contentStyleType() native "return this.contentStyleType;";

  void set contentStyleType(String value) native "this.contentStyleType = value;";

  num get currentScale() native "return this.currentScale;";

  void set currentScale(num value) native "this.currentScale = value;";

  SVGPoint get currentTranslate() native "return this.currentTranslate;";

  SVGAnimatedLength get height() native "return this.height;";

  num get pixelUnitToMillimeterX() native "return this.pixelUnitToMillimeterX;";

  num get pixelUnitToMillimeterY() native "return this.pixelUnitToMillimeterY;";

  num get screenPixelToMillimeterX() native "return this.screenPixelToMillimeterX;";

  num get screenPixelToMillimeterY() native "return this.screenPixelToMillimeterY;";

  bool get useCurrentView() native "return this.useCurrentView;";

  void set useCurrentView(bool value) native "this.useCurrentView = value;";

  SVGRect get viewport() native "return this.viewport;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

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

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}
