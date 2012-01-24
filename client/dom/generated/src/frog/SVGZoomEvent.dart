
class SVGZoomEventJS extends UIEventJS implements SVGZoomEvent native "*SVGZoomEvent" {

  num get newScale() native "return this.newScale;";

  SVGPointJS get newTranslate() native "return this.newTranslate;";

  num get previousScale() native "return this.previousScale;";

  SVGPointJS get previousTranslate() native "return this.previousTranslate;";

  SVGRectJS get zoomRectScreen() native "return this.zoomRectScreen;";
}
