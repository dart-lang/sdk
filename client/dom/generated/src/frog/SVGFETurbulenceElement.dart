
class SVGFETurbulenceElementJS extends SVGElementJS implements SVGFETurbulenceElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  SVGAnimatedNumberJS get baseFrequencyX() native "return this.baseFrequencyX;";

  SVGAnimatedNumberJS get baseFrequencyY() native "return this.baseFrequencyY;";

  SVGAnimatedIntegerJS get numOctaves() native "return this.numOctaves;";

  SVGAnimatedNumberJS get seed() native "return this.seed;";

  SVGAnimatedEnumerationJS get stitchTiles() native "return this.stitchTiles;";

  SVGAnimatedEnumerationJS get type() native "return this.type;";

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
