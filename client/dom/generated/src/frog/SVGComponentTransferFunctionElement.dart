
class SVGComponentTransferFunctionElement extends SVGElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  SVGAnimatedNumber get amplitude() native "return this.amplitude;";

  SVGAnimatedNumber get exponent() native "return this.exponent;";

  SVGAnimatedNumber get intercept() native "return this.intercept;";

  SVGAnimatedNumber get offset() native "return this.offset;";

  SVGAnimatedNumber get slope() native "return this.slope;";

  SVGAnimatedNumberList get tableValues() native "return this.tableValues;";

  SVGAnimatedEnumeration get type() native "return this.type;";
}
