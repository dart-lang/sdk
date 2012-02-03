
class _SVGStopElementJs extends _SVGElementJs implements SVGStopElement native "*SVGStopElement" {

  _SVGAnimatedNumberJs get offset() native "return this.offset;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
