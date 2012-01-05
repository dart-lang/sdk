
class SVGGradientElement extends SVGElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformList gradientTransform;

  SVGAnimatedEnumeration gradientUnits;

  SVGAnimatedEnumeration spreadMethod;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
