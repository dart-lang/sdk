
class _SVGSVGElementImpl extends _SVGElementImpl implements SVGSVGElement native "*SVGSVGElement" {

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  final _SVGPointImpl currentTranslate;

  final _SVGAnimatedLengthImpl height;

  final num pixelUnitToMillimeterX;

  final num pixelUnitToMillimeterY;

  final num screenPixelToMillimeterX;

  final num screenPixelToMillimeterY;

  bool useCurrentView;

  final _SVGRectImpl viewport;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  bool animationsPaused() native;

  bool checkEnclosure(_SVGElementImpl element, _SVGRectImpl rect) native;

  bool checkIntersection(_SVGElementImpl element, _SVGRectImpl rect) native;

  _SVGAngleImpl createSVGAngle() native;

  _SVGLengthImpl createSVGLength() native;

  _SVGMatrixImpl createSVGMatrix() native;

  _SVGNumberImpl createSVGNumber() native;

  _SVGPointImpl createSVGPoint() native;

  _SVGRectImpl createSVGRect() native;

  _SVGTransformImpl createSVGTransform() native;

  _SVGTransformImpl createSVGTransformFromMatrix(_SVGMatrixImpl matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  _ElementImpl getElementById(String elementId) native;

  _NodeListImpl getEnclosureList(_SVGRectImpl rect, _SVGElementImpl referenceElement) native;

  _NodeListImpl getIntersectionList(_SVGRectImpl rect, _SVGElementImpl referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}
