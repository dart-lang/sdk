
class SVGLocatable native "*SVGLocatable" {

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
