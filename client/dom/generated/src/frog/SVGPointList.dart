
class _SVGPointListJs extends _DOMTypeJs implements SVGPointList native "*SVGPointList" {

  int get numberOfItems() native "return this.numberOfItems;";

  _SVGPointJs appendItem(_SVGPointJs item) native;

  void clear() native;

  _SVGPointJs getItem(int index) native;

  _SVGPointJs initialize(_SVGPointJs item) native;

  _SVGPointJs insertItemBefore(_SVGPointJs item, int index) native;

  _SVGPointJs removeItem(int index) native;

  _SVGPointJs replaceItem(_SVGPointJs item, int index) native;
}
