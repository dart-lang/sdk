
class _SVGLineElementJs extends _SVGElementJs implements SVGLineElement native "*SVGLineElement" {

  final _SVGAnimatedLengthJs x1;

  final _SVGAnimatedLengthJs x2;

  final _SVGAnimatedLengthJs y1;

  final _SVGAnimatedLengthJs y2;

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

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}
