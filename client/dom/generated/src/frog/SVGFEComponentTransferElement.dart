
class SVGFEComponentTransferElementJs extends SVGElementJs implements SVGFEComponentTransferElement native "*SVGFEComponentTransferElement" {

  SVGAnimatedStringJs get in1() native "return this.in1;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJs get height() native "return this.height;";

  SVGAnimatedStringJs get result() native "return this.result;";

  SVGAnimatedLengthJs get width() native "return this.width;";

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
