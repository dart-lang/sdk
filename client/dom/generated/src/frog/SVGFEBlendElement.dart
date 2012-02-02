
class _SVGFEBlendElementJs extends _SVGElementJs implements SVGFEBlendElement native "*SVGFEBlendElement" {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedStringJs get in2() native "return this.in2;";

  _SVGAnimatedEnumerationJs get mode() native "return this.mode;";

  // From SVGFilterPrimitiveStandardAttributes

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedStringJs get result() native "return this.result;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
