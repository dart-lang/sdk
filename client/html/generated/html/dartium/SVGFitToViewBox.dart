
class _SVGFitToViewBoxImpl extends _DOMTypeBase implements SVGFitToViewBox {
  _SVGFitToViewBoxImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);
}
