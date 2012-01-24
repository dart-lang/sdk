
class SVGFEDisplacementMapElementJs extends SVGElementJs implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedStringJs get in2() native "return this.in2;";

  SVGAnimatedNumberJs get scale() native "return this.scale;";

  SVGAnimatedEnumerationJs get xChannelSelector() native "return this.xChannelSelector;";

  SVGAnimatedEnumerationJs get yChannelSelector() native "return this.yChannelSelector;";

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
