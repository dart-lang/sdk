
class _SVGFilterElementJs extends _SVGElementJs implements SVGFilterElement native "*SVGFilterElement" {

  final _SVGAnimatedIntegerJs filterResX;

  final _SVGAnimatedIntegerJs filterResY;

  final _SVGAnimatedEnumerationJs filterUnits;

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedEnumerationJs primitiveUnits;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

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
}
