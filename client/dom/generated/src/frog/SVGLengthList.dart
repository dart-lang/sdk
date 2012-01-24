
class SVGLengthListJS implements SVGLengthList native "*SVGLengthList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGLengthJS appendItem(SVGLengthJS item) native;

  void clear() native;

  SVGLengthJS getItem(int index) native;

  SVGLengthJS initialize(SVGLengthJS item) native;

  SVGLengthJS insertItemBefore(SVGLengthJS item, int index) native;

  SVGLengthJS removeItem(int index) native;

  SVGLengthJS replaceItem(SVGLengthJS item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
