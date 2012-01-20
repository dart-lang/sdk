
class SVGFEDiffuseLightingElement extends SVGElement native "*SVGFEDiffuseLightingElement" {

  SVGAnimatedNumber get diffuseConstant() native "return this.diffuseConstant;";

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumber get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumber get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedNumber get surfaceScale() native "return this.surfaceScale;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}
