
class _SVGFEDropShadowElementJs extends _SVGElementJs implements SVGFEDropShadowElement native "*SVGFEDropShadowElement" {

  final _SVGAnimatedNumberJs dx;

  final _SVGAnimatedNumberJs dy;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberJs stdDeviationX;

  final _SVGAnimatedNumberJs stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

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
