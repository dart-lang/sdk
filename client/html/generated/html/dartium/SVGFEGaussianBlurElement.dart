
class _SVGFEGaussianBlurElementImpl extends _SVGElementImpl implements SVGFEGaussianBlurElement {
  _SVGFEGaussianBlurElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedString get in1() => _wrap(_ptr.in1);

  SVGAnimatedNumber get stdDeviationX() => _wrap(_ptr.stdDeviationX);

  SVGAnimatedNumber get stdDeviationY() => _wrap(_ptr.stdDeviationY);

  void setStdDeviation(num stdDeviationX, num stdDeviationY) {
    _ptr.setStdDeviation(_unwrap(stdDeviationX), _unwrap(stdDeviationY));
    return;
  }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() => _wrap(_ptr.height);

  SVGAnimatedString get result() => _wrap(_ptr.result);

  SVGAnimatedLength get width() => _wrap(_ptr.width);

  SVGAnimatedLength get x() => _wrap(_ptr.x);

  SVGAnimatedLength get y() => _wrap(_ptr.y);

  // From SVGStylable

  SVGAnimatedString get _svgClassName() => _wrap(_ptr.className);

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  CSSValue getPresentationAttribute(String name) {
    return _wrap(_ptr.getPresentationAttribute(_unwrap(name)));
  }
}
