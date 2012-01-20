
class SVGFETurbulenceElement extends SVGElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  SVGAnimatedNumber get baseFrequencyX() native "return this.baseFrequencyX;";

  SVGAnimatedNumber get baseFrequencyY() native "return this.baseFrequencyY;";

  SVGAnimatedInteger get numOctaves() native "return this.numOctaves;";

  SVGAnimatedNumber get seed() native "return this.seed;";

  SVGAnimatedEnumeration get stitchTiles() native "return this.stitchTiles;";

  SVGAnimatedEnumeration get type() native "return this.type;";

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
