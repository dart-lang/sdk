
class _SVGGradientElementJs extends _SVGElementJs implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  final _SVGAnimatedTransformListJs gradientTransform;

  final _SVGAnimatedEnumerationJs gradientUnits;

  final _SVGAnimatedEnumerationJs spreadMethod;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}
