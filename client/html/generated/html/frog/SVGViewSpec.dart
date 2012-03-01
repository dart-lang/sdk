
class _SVGViewSpecImpl extends _SVGZoomAndPanImpl implements SVGViewSpec native "*SVGViewSpec" {

  final String preserveAspectRatioString;

  final _SVGTransformListImpl transform;

  final String transformString;

  final String viewBoxString;

  final _SVGElementImpl viewTarget;

  final String viewTargetString;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}
