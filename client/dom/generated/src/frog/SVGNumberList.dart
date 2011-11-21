
class SVGNumberList native "SVGNumberList" {

  int numberOfItems;

  SVGNumber appendItem(SVGNumber item) native;

  void clear() native;

  SVGNumber getItem(int index) native;

  SVGNumber initialize(SVGNumber item) native;

  SVGNumber insertItemBefore(SVGNumber item, int index) native;

  SVGNumber removeItem(int index) native;

  SVGNumber replaceItem(SVGNumber item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
