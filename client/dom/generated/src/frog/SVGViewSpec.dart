
class SVGViewSpec extends SVGZoomAndPan native "*SVGViewSpec" {

  String get preserveAspectRatioString() native "return this.preserveAspectRatioString;";

  SVGTransformList get transform() native "return this.transform;";

  String get transformString() native "return this.transformString;";

  String get viewBoxString() native "return this.viewBoxString;";

  SVGElement get viewTarget() native "return this.viewTarget;";

  String get viewTargetString() native "return this.viewTargetString;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}
