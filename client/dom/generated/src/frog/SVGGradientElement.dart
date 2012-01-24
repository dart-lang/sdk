
class SVGGradientElementJS extends SVGElementJS implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformListJS get gradientTransform() native "return this.gradientTransform;";

  SVGAnimatedEnumerationJS get gradientUnits() native "return this.gradientUnits;";

  SVGAnimatedEnumerationJS get spreadMethod() native "return this.spreadMethod;";

  // From SVGURIReference

  SVGAnimatedStringJS get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
