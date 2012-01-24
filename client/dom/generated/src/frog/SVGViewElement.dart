
class SVGViewElementJS extends SVGElementJS implements SVGViewElement native "*SVGViewElement" {

  SVGStringListJS get viewTarget() native "return this.viewTarget;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJS get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJS get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}
