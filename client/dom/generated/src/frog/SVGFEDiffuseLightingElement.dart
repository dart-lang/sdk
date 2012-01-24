
class SVGFEDiffuseLightingElementJs extends SVGElementJs implements SVGFEDiffuseLightingElement native "*SVGFEDiffuseLightingElement" {

  SVGAnimatedNumberJs get diffuseConstant() native "return this.diffuseConstant;";

  SVGAnimatedStringJs get in1() native "return this.in1;";

  SVGAnimatedNumberJs get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumberJs get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

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
