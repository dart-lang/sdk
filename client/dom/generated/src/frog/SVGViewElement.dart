
class _SVGViewElementJs extends _SVGElementJs implements SVGViewElement native "*SVGViewElement" {

  _SVGStringListJs get viewTarget() native "return this.viewTarget;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGFitToViewBox

  _SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  _SVGAnimatedRectJs get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}
