
class SVGGradientElementJs extends SVGElementJs implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformListJs get gradientTransform() native "return this.gradientTransform;";

  SVGAnimatedEnumerationJs get gradientUnits() native "return this.gradientUnits;";

  SVGAnimatedEnumerationJs get spreadMethod() native "return this.spreadMethod;";

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
