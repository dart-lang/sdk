
class _SVGFEColorMatrixElementJs extends _SVGElementJs implements SVGFEColorMatrixElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedEnumerationJs type;

  final _SVGAnimatedNumberListJs values;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}
