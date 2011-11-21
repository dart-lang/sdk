
class SVGGradientElement extends SVGElement native "SVGGradientElement" {

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
