
class SVGPathSegListJs extends DOMTypeJs implements SVGPathSegList native "*SVGPathSegList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPathSegJs appendItem(SVGPathSegJs newItem) native;

  void clear() native;

  SVGPathSegJs getItem(int index) native;

  SVGPathSegJs initialize(SVGPathSegJs newItem) native;

  SVGPathSegJs insertItemBefore(SVGPathSegJs newItem, int index) native;

  SVGPathSegJs removeItem(int index) native;

  SVGPathSegJs replaceItem(SVGPathSegJs newItem, int index) native;
}
