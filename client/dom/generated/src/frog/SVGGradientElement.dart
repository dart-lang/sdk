
class SVGGradientElement extends SVGElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformList get gradientTransform() native "return this.gradientTransform;";

  SVGAnimatedEnumeration get gradientUnits() native "return this.gradientUnits;";

  SVGAnimatedEnumeration get spreadMethod() native "return this.spreadMethod;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
