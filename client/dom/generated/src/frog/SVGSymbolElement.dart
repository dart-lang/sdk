
class SVGSymbolElement extends SVGElement native "SVGSymbolElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}
