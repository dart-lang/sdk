
class SVGFEColorMatrixElement extends SVGElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedEnumeration get type() native "return this.type;";

  SVGAnimatedNumberList get values() native "return this.values;";

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
