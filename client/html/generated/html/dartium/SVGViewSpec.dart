
class _SVGViewSpecImpl extends _SVGZoomAndPanImpl implements SVGViewSpec {
  _SVGViewSpecImpl._wrap(ptr) : super._wrap(ptr);

  String get preserveAspectRatioString() => _wrap(_ptr.preserveAspectRatioString);

  SVGTransformList get transform() => _wrap(_ptr.transform);

  String get transformString() => _wrap(_ptr.transformString);

  String get viewBoxString() => _wrap(_ptr.viewBoxString);

  SVGElement get viewTarget() => _wrap(_ptr.viewTarget);

  String get viewTargetString() => _wrap(_ptr.viewTargetString);

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);
}
