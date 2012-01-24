
class SVGFEBlendElementJs extends SVGElementJs implements SVGFEBlendElement native "*SVGFEBlendElement" {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedStringJs get in2() native "return this.in2;";

  SVGAnimatedEnumerationJs get mode() native "return this.mode;";

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
