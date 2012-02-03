
class _SVGZoomEventJs extends _UIEventJs implements SVGZoomEvent native "*SVGZoomEvent" {

  num get newScale() native "return this.newScale;";

  _SVGPointJs get newTranslate() native "return this.newTranslate;";

  num get previousScale() native "return this.previousScale;";

  _SVGPointJs get previousTranslate() native "return this.previousTranslate;";

  _SVGRectJs get zoomRectScreen() native "return this.zoomRectScreen;";
}
