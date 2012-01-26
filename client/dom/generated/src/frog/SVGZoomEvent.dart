
class SVGZoomEventJs extends UIEventJs implements SVGZoomEvent native "*SVGZoomEvent" {

  num get newScale() native "return this.newScale;";

  SVGPointJs get newTranslate() native "return this.newTranslate;";

  num get previousScale() native "return this.previousScale;";

  SVGPointJs get previousTranslate() native "return this.previousTranslate;";

  SVGRectJs get zoomRectScreen() native "return this.zoomRectScreen;";
}
