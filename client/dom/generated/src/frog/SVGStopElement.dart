
class SVGStopElement extends SVGElement native "*SVGStopElement" {

  SVGAnimatedNumber offset;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
