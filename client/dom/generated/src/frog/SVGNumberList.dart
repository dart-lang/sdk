
class SVGNumberListJS implements SVGNumberList native "*SVGNumberList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGNumberJS appendItem(SVGNumberJS item) native;

  void clear() native;

  SVGNumberJS getItem(int index) native;

  SVGNumberJS initialize(SVGNumberJS item) native;

  SVGNumberJS insertItemBefore(SVGNumberJS item, int index) native;

  SVGNumberJS removeItem(int index) native;

  SVGNumberJS replaceItem(SVGNumberJS item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
