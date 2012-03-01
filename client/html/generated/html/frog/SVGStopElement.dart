
class _SVGStopElementImpl extends _SVGElementImpl implements SVGStopElement native "*SVGStopElement" {

  final _SVGAnimatedNumberImpl offset;

  // From SVGStylable

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
