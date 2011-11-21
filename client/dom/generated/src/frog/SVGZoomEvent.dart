
class SVGZoomEvent extends UIEvent native "SVGZoomEvent" {

  num newScale;

  SVGPoint newTranslate;

  num previousScale;

  SVGPoint previousTranslate;

  SVGRect zoomRectScreen;
}
