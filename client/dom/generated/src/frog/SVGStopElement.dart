
class SVGStopElementJS extends SVGElementJS implements SVGStopElement native "*SVGStopElement" {

  SVGAnimatedNumberJS get offset() native "return this.offset;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
