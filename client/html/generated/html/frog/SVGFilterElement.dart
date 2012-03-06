
class _SVGFilterElementImpl extends _SVGElementImpl implements SVGFilterElement native "*SVGFilterElement" {

  final _SVGAnimatedIntegerImpl filterResX;

  final _SVGAnimatedIntegerImpl filterResY;

  final _SVGAnimatedEnumerationImpl filterUnits;

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl primitiveUnits;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

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
}
