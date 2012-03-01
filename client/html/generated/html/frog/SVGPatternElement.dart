
class _SVGPatternElementImpl extends _SVGElementImpl implements SVGPatternElement native "*SVGPatternElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl patternContentUnits;

  final _SVGAnimatedTransformListImpl patternTransform;

  final _SVGAnimatedEnumerationImpl patternUnits;

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

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}
