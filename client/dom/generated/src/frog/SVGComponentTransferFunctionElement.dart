
class SVGComponentTransferFunctionElementJS extends SVGElementJS implements SVGComponentTransferFunctionElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  SVGAnimatedNumberJS get amplitude() native "return this.amplitude;";

  SVGAnimatedNumberJS get exponent() native "return this.exponent;";

  SVGAnimatedNumberJS get intercept() native "return this.intercept;";

  SVGAnimatedNumberJS get offset() native "return this.offset;";

  SVGAnimatedNumberJS get slope() native "return this.slope;";

  SVGAnimatedNumberListJS get tableValues() native "return this.tableValues;";

  SVGAnimatedEnumerationJS get type() native "return this.type;";
}
