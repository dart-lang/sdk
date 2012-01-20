
class SVGPointList native "*SVGPointList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPoint appendItem(SVGPoint item) native;

  void clear() native;

  SVGPoint getItem(int index) native;

  SVGPoint initialize(SVGPoint item) native;

  SVGPoint insertItemBefore(SVGPoint item, int index) native;

  SVGPoint removeItem(int index) native;

  SVGPoint replaceItem(SVGPoint item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
