
class SVGFETurbulenceElementJs extends SVGElementJs implements SVGFETurbulenceElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  SVGAnimatedNumberJs get baseFrequencyX() native "return this.baseFrequencyX;";

  SVGAnimatedNumberJs get baseFrequencyY() native "return this.baseFrequencyY;";

  SVGAnimatedIntegerJs get numOctaves() native "return this.numOctaves;";

  SVGAnimatedNumberJs get seed() native "return this.seed;";

  SVGAnimatedEnumerationJs get stitchTiles() native "return this.stitchTiles;";

  SVGAnimatedEnumerationJs get type() native "return this.type;";

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
