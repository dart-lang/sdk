
class SVGFESpecularLightingElementJs extends SVGElementJs implements SVGFESpecularLightingElement native "*SVGFESpecularLightingElement" {

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedNumberJs get specularConstant() native "return this.specularConstant;";

  SVGAnimatedNumberJs get specularExponent() native "return this.specularExponent;";

  SVGAnimatedNumberJs get surfaceScale() native "return this.surfaceScale;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLengthJs get height() native "return this.height;";

  SVGAnimatedStringJs get result() native "return this.result;";

  SVGAnimatedLengthJs get width() native "return this.width;";

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;
}
