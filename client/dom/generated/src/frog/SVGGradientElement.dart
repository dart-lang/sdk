
class _SVGGradientElementJs extends _SVGElementJs implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  _SVGAnimatedTransformListJs get gradientTransform() native "return this.gradientTransform;";

  _SVGAnimatedEnumerationJs get gradientUnits() native "return this.gradientUnits;";

  _SVGAnimatedEnumerationJs get spreadMethod() native "return this.spreadMethod;";

  // From SVGURIReference

  _SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
