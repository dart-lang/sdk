
class _SVGFETurbulenceElementJs extends _SVGElementJs implements SVGFETurbulenceElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  _SVGAnimatedNumberJs get baseFrequencyX() native "return this.baseFrequencyX;";

  _SVGAnimatedNumberJs get baseFrequencyY() native "return this.baseFrequencyY;";

  _SVGAnimatedIntegerJs get numOctaves() native "return this.numOctaves;";

  _SVGAnimatedNumberJs get seed() native "return this.seed;";

  _SVGAnimatedEnumerationJs get stitchTiles() native "return this.stitchTiles;";

  _SVGAnimatedEnumerationJs get type() native "return this.type;";

  // From SVGFilterPrimitiveStandardAttributes

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedStringJs get result() native "return this.result;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;
}
