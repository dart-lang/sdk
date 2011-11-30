
class SVGFEColorMatrixElement extends SVGElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  SVGAnimatedString in1;

  SVGAnimatedEnumeration type;

  SVGAnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
