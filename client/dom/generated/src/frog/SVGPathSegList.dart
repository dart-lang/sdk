
class _SVGPathSegListJs extends _DOMTypeJs implements SVGPathSegList native "*SVGPathSegList" {

  final int numberOfItems;

  _SVGPathSegJs appendItem(_SVGPathSegJs newItem) native;

  void clear() native;

  _SVGPathSegJs getItem(int index) native;

  _SVGPathSegJs initialize(_SVGPathSegJs newItem) native;

  _SVGPathSegJs insertItemBefore(_SVGPathSegJs newItem, int index) native;

  _SVGPathSegJs removeItem(int index) native;

  _SVGPathSegJs replaceItem(_SVGPathSegJs newItem, int index) native;
}
