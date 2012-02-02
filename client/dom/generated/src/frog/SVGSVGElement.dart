
class _SVGSVGElementJs extends _SVGElementJs implements SVGSVGElement native "*SVGSVGElement" {

  String get contentScriptType() native "return this.contentScriptType;";

  void set contentScriptType(String value) native "this.contentScriptType = value;";

  String get contentStyleType() native "return this.contentStyleType;";

  void set contentStyleType(String value) native "this.contentStyleType = value;";

  num get currentScale() native "return this.currentScale;";

  void set currentScale(num value) native "this.currentScale = value;";

  _SVGPointJs get currentTranslate() native "return this.currentTranslate;";

  _SVGAnimatedLengthJs get height() native "return this.height;";

  num get pixelUnitToMillimeterX() native "return this.pixelUnitToMillimeterX;";

  num get pixelUnitToMillimeterY() native "return this.pixelUnitToMillimeterY;";

  num get screenPixelToMillimeterX() native "return this.screenPixelToMillimeterX;";

  num get screenPixelToMillimeterY() native "return this.screenPixelToMillimeterY;";

  bool get useCurrentView() native "return this.useCurrentView;";

  void set useCurrentView(bool value) native "this.useCurrentView = value;";

  _SVGRectJs get viewport() native "return this.viewport;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  bool animationsPaused() native;

  bool checkEnclosure(_SVGElementJs element, _SVGRectJs rect) native;

  bool checkIntersection(_SVGElementJs element, _SVGRectJs rect) native;

  _SVGAngleJs createSVGAngle() native;

  _SVGLengthJs createSVGLength() native;

  _SVGMatrixJs createSVGMatrix() native;

  _SVGNumberJs createSVGNumber() native;

  _SVGPointJs createSVGPoint() native;

  _SVGRectJs createSVGRect() native;

  _SVGTransformJs createSVGTransform() native;

  _SVGTransformJs createSVGTransformFromMatrix(_SVGMatrixJs matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  _ElementJs getElementById(String elementId) native;

  _NodeListJs getEnclosureList(_SVGRectJs rect, _SVGElementJs referenceElement) native;

  _NodeListJs getIntersectionList(_SVGRectJs rect, _SVGElementJs referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  _SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  _SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  _SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGLocatable

  _SVGElementJs get farthestViewportElement() native "return this.farthestViewportElement;";

  _SVGElementJs get nearestViewportElement() native "return this.nearestViewportElement;";

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;

  // From SVGFitToViewBox

  _SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  _SVGAnimatedRectJs get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}
