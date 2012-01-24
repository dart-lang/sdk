
class SVGPathSegListJS implements SVGPathSegList native "*SVGPathSegList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPathSegJS appendItem(SVGPathSegJS newItem) native;

  void clear() native;

  SVGPathSegJS getItem(int index) native;

  SVGPathSegJS initialize(SVGPathSegJS newItem) native;

  SVGPathSegJS insertItemBefore(SVGPathSegJS newItem, int index) native;

  SVGPathSegJS removeItem(int index) native;

  SVGPathSegJS replaceItem(SVGPathSegJS newItem, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
