
class _SVGStylableJs extends _DOMTypeJs implements SVGStylable native "*SVGStylable" {

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
