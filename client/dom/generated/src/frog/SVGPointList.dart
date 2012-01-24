
class SVGPointListJs extends DOMTypeJs implements SVGPointList native "*SVGPointList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPointJs appendItem(SVGPointJs item) native;

  void clear() native;

  SVGPointJs getItem(int index) native;

  SVGPointJs initialize(SVGPointJs item) native;

  SVGPointJs insertItemBefore(SVGPointJs item, int index) native;

  SVGPointJs removeItem(int index) native;

  SVGPointJs replaceItem(SVGPointJs item, int index) native;
}
