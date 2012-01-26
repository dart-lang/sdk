
class SVGComponentTransferFunctionElementJs extends SVGElementJs implements SVGComponentTransferFunctionElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  SVGAnimatedNumberJs get amplitude() native "return this.amplitude;";

  SVGAnimatedNumberJs get exponent() native "return this.exponent;";

  SVGAnimatedNumberJs get intercept() native "return this.intercept;";

  SVGAnimatedNumberJs get offset() native "return this.offset;";

  SVGAnimatedNumberJs get slope() native "return this.slope;";

  SVGAnimatedNumberListJs get tableValues() native "return this.tableValues;";

  SVGAnimatedEnumerationJs get type() native "return this.type;";
}
