
class SVGViewElementJs extends SVGElementJs implements SVGViewElement native "*SVGViewElement" {

  SVGStringListJs get viewTarget() native "return this.viewTarget;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJs get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}
