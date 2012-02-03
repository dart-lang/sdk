
class _SVGComponentTransferFunctionElementJs extends _SVGElementJs implements SVGComponentTransferFunctionElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  _SVGAnimatedNumberJs get amplitude() native "return this.amplitude;";

  _SVGAnimatedNumberJs get exponent() native "return this.exponent;";

  _SVGAnimatedNumberJs get intercept() native "return this.intercept;";

  _SVGAnimatedNumberJs get offset() native "return this.offset;";

  _SVGAnimatedNumberJs get slope() native "return this.slope;";

  _SVGAnimatedNumberListJs get tableValues() native "return this.tableValues;";

  _SVGAnimatedEnumerationJs get type() native "return this.type;";
}
