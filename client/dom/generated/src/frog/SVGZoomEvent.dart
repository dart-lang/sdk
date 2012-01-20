
class SVGZoomEvent extends UIEvent native "*SVGZoomEvent" {

  num get newScale() native "return this.newScale;";

  SVGPoint get newTranslate() native "return this.newTranslate;";

  num get previousScale() native "return this.previousScale;";

  SVGPoint get previousTranslate() native "return this.previousTranslate;";

  SVGRect get zoomRectScreen() native "return this.zoomRectScreen;";
}
