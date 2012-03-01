
class _SVGMaskElementImpl extends _SVGElementImpl implements SVGMaskElement native "*SVGMaskElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl maskContentUnits;

  final _SVGAnimatedEnumerationImpl maskUnits;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

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
}
