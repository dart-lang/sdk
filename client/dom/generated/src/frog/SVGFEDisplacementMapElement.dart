
class _SVGFEDisplacementMapElementJs extends _SVGElementJs implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedStringJs in2;

  final _SVGAnimatedNumberJs scale;

  final _SVGAnimatedEnumerationJs xChannelSelector;

  final _SVGAnimatedEnumerationJs yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}
