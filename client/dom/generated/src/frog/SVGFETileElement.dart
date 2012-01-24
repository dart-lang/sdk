
class SVGFETileElementJS extends SVGElementJS implements SVGFETileElement native "*SVGFETileElement" {

  SVGAnimatedStringJS get in1() native "return this.in1;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJS get height() native "return this.height;";

  SVGAnimatedStringJS get result() native "return this.result;";

  SVGAnimatedLengthJS get width() native "return this.width;";

  SVGAnimatedLengthJS get x() native "return this.x;";

  SVGAnimatedLengthJS get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
