
class SVGPathSegList native "*SVGPathSegList" {

  int numberOfItems;

  SVGPathSeg appendItem(SVGPathSeg newItem) native;

  void clear() native;

  SVGPathSeg getItem(int index) native;

  SVGPathSeg initialize(SVGPathSeg newItem) native;

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) native;

  SVGPathSeg removeItem(int index) native;

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
