
class _SVGComponentTransferFunctionElementImpl extends _SVGElementImpl implements SVGComponentTransferFunctionElement {
  _SVGComponentTransferFunctionElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedNumber get amplitude() => _wrap(_ptr.amplitude);

  SVGAnimatedNumber get exponent() => _wrap(_ptr.exponent);

  SVGAnimatedNumber get intercept() => _wrap(_ptr.intercept);

  SVGAnimatedNumber get offset() => _wrap(_ptr.offset);

  SVGAnimatedNumber get slope() => _wrap(_ptr.slope);

  SVGAnimatedNumberList get tableValues() => _wrap(_ptr.tableValues);

  SVGAnimatedEnumeration get type() => _wrap(_ptr.type);
}
