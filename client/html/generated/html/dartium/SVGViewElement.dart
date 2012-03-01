
class _SVGViewElementImpl extends _SVGElementImpl implements SVGViewElement {
  _SVGViewElementImpl._wrap(ptr) : super._wrap(ptr);

  SVGStringList get viewTarget() => _wrap(_ptr.viewTarget);

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() => _wrap(_ptr.externalResourcesRequired);

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() => _wrap(_ptr.preserveAspectRatio);

  SVGAnimatedRect get viewBox() => _wrap(_ptr.viewBox);

  // From SVGZoomAndPan

  int get zoomAndPan() => _wrap(_ptr.zoomAndPan);

  void set zoomAndPan(int value) { _ptr.zoomAndPan = _unwrap(value); }
}
