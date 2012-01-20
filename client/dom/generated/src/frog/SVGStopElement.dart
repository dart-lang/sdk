
class SVGStopElement extends SVGElement native "*SVGStopElement" {

  SVGAnimatedNumber get offset() native "return this.offset;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
