
class _SVGSVGElementJs extends _SVGElementJs implements SVGSVGElement native "*SVGSVGElement" {

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  final _SVGPointJs currentTranslate;

  final _SVGAnimatedLengthJs height;

  final num pixelUnitToMillimeterX;

  final num pixelUnitToMillimeterY;

  final num screenPixelToMillimeterX;

  final num screenPixelToMillimeterY;

  bool useCurrentView;

  final _SVGRectJs viewport;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

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

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}
