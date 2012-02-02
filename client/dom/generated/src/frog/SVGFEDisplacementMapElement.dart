
class _SVGFEDisplacementMapElementJs extends _SVGElementJs implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  _SVGAnimatedStringJs get in1() native "return this.in1;";

  _SVGAnimatedStringJs get in2() native "return this.in2;";

  _SVGAnimatedNumberJs get scale() native "return this.scale;";

  _SVGAnimatedEnumerationJs get xChannelSelector() native "return this.xChannelSelector;";

  _SVGAnimatedEnumerationJs get yChannelSelector() native "return this.yChannelSelector;";

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
