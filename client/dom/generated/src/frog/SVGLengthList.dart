
class SVGLengthList native "*SVGLengthList" {

  int numberOfItems;

  SVGLength appendItem(SVGLength item) native;

  void clear() native;

  SVGLength getItem(int index) native;

  SVGLength initialize(SVGLength item) native;

  SVGLength insertItemBefore(SVGLength item, int index) native;

  SVGLength removeItem(int index) native;

  SVGLength replaceItem(SVGLength item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
