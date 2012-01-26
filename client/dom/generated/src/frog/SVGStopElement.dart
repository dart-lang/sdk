
class SVGStopElementJs extends SVGElementJs implements SVGStopElement native "*SVGStopElement" {

  SVGAnimatedNumberJs get offset() native "return this.offset;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
