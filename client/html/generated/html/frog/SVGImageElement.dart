
class _SVGImageElementImpl extends _SVGElementImpl implements SVGImageElement native "*SVGImageElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

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

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}
