
class _SVGGradientElementImpl extends _SVGElementImpl implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  final _SVGAnimatedTransformListImpl gradientTransform;

  final _SVGAnimatedEnumerationImpl gradientUnits;

  final _SVGAnimatedEnumerationImpl spreadMethod;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
