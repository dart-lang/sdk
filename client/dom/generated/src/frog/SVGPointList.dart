
class SVGPointListJS implements SVGPointList native "*SVGPointList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPointJS appendItem(SVGPointJS item) native;

  void clear() native;

  SVGPointJS getItem(int index) native;

  SVGPointJS initialize(SVGPointJS item) native;

  SVGPointJS insertItemBefore(SVGPointJS item, int index) native;

  SVGPointJS removeItem(int index) native;

  SVGPointJS replaceItem(SVGPointJS item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
