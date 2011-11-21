
class SVGDescElement extends SVGElement native "SVGDescElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
