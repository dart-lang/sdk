
class SVGViewSpecJs extends SVGZoomAndPanJs implements SVGViewSpec native "*SVGViewSpec" {

  String get preserveAspectRatioString() native "return this.preserveAspectRatioString;";

  SVGTransformListJs get transform() native "return this.transform;";

  String get transformString() native "return this.transformString;";

  String get viewBoxString() native "return this.viewBoxString;";

  SVGElementJs get viewTarget() native "return this.viewTarget;";

  String get viewTargetString() native "return this.viewTargetString;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJs get viewBox() native "return this.viewBox;";
}
