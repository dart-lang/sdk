
class SVGViewSpecJS extends SVGZoomAndPanJS implements SVGViewSpec native "*SVGViewSpec" {

  String get preserveAspectRatioString() native "return this.preserveAspectRatioString;";

  SVGTransformListJS get transform() native "return this.transform;";

  String get transformString() native "return this.transformString;";

  String get viewBoxString() native "return this.viewBoxString;";

  SVGElementJS get viewTarget() native "return this.viewTarget;";

  String get viewTargetString() native "return this.viewTargetString;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJS get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJS get viewBox() native "return this.viewBox;";
}
