
class _SVGRadialGradientElementImpl extends _SVGGradientElementImpl implements SVGRadialGradientElement {
  _SVGRadialGradientElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedLength get cx() => _wrap(_ptr.cx);

  SVGAnimatedLength get cy() => _wrap(_ptr.cy);

  SVGAnimatedLength get fx() => _wrap(_ptr.fx);

  SVGAnimatedLength get fy() => _wrap(_ptr.fy);

  SVGAnimatedLength get r() => _wrap(_ptr.r);
}
