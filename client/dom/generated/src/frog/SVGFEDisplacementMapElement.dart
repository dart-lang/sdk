
class SVGFEDisplacementMapElement extends SVGElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedString get in2() native "return this.in2;";

  SVGAnimatedNumber get scale() native "return this.scale;";

  SVGAnimatedEnumeration get xChannelSelector() native "return this.xChannelSelector;";

  SVGAnimatedEnumeration get yChannelSelector() native "return this.yChannelSelector;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
