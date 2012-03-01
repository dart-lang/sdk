
class _SVGFEDisplacementMapElementImpl extends _SVGElementImpl implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedStringImpl in2;

  final _SVGAnimatedNumberImpl scale;

  final _SVGAnimatedEnumerationImpl xChannelSelector;

  final _SVGAnimatedEnumerationImpl yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
