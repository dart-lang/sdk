
class _SVGLinearGradientElementImpl extends _SVGGradientElementImpl implements SVGLinearGradientElement {
  _SVGLinearGradientElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedLength get x1() => _wrap(_ptr.x1);

  SVGAnimatedLength get x2() => _wrap(_ptr.x2);

  SVGAnimatedLength get y1() => _wrap(_ptr.y1);

  SVGAnimatedLength get y2() => _wrap(_ptr.y2);
}
