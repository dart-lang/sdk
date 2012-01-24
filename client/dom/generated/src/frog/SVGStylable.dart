
class SVGStylableJs extends DOMTypeJs implements SVGStylable native "*SVGStylable" {

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
