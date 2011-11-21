
class SVGFilterElement extends SVGElement native "SVGFilterElement" {

  SVGAnimatedInteger filterResX;

  SVGAnimatedInteger filterResY;

  SVGAnimatedEnumeration filterUnits;

  SVGAnimatedLength height;

  SVGAnimatedEnumeration primitiveUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
