
class SVGLocatable native "*SVGLocatable" {

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
