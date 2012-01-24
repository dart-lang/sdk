
class SVGFESpecularLightingElementJS extends SVGElementJS implements SVGFESpecularLightingElement native "*SVGFESpecularLightingElement" {

  SVGAnimatedStringJS get in1() native "return this.in1;";

  SVGAnimatedNumberJS get specularConstant() native "return this.specularConstant;";

  SVGAnimatedNumberJS get specularExponent() native "return this.specularExponent;";

  SVGAnimatedNumberJS get surfaceScale() native "return this.surfaceScale;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJS get height() native "return this.height;";

  SVGAnimatedStringJS get result() native "return this.result;";

  SVGAnimatedLengthJS get width() native "return this.width;";

  SVGAnimatedLengthJS get x() native "return this.x;";

  SVGAnimatedLengthJS get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;
}
