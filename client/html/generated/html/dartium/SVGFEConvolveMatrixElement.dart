
class _SVGFEConvolveMatrixElementImpl extends _SVGElementImpl implements SVGFEConvolveMatrixElement {
  _SVGFEConvolveMatrixElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedNumber get bias() => _wrap(_ptr.bias);

  SVGAnimatedNumber get divisor() => _wrap(_ptr.divisor);

  SVGAnimatedEnumeration get edgeMode() => _wrap(_ptr.edgeMode);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedNumberList get kernelMatrix() => _wrap(_ptr.kernelMatrix);

  SVGAnimatedNumber get kernelUnitLengthX() => _wrap(_ptr.kernelUnitLengthX);

  SVGAnimatedNumber get kernelUnitLengthY() => _wrap(_ptr.kernelUnitLengthY);

  SVGAnimatedInteger get orderX() => _wrap(_ptr.orderX);

  SVGAnimatedInteger get orderY() => _wrap(_ptr.orderY);

  SVGAnimatedBoolean get preserveAlpha() => _wrap(_ptr.preserveAlpha);

  SVGAnimatedInteger get targetX() => _wrap(_ptr.targetX);

  SVGAnimatedInteger get targetY() => _wrap(_ptr.targetY);

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedString get result() => _wrap(_ptr.result);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  // From SVGStylable

  SVGAnimatedString get _className() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
