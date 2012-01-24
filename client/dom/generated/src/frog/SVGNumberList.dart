
class SVGNumberListJs extends DOMTypeJs implements SVGNumberList native "*SVGNumberList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGNumberJs appendItem(SVGNumberJs item) native;

  void clear() native;

  SVGNumberJs getItem(int index) native;

  SVGNumberJs initialize(SVGNumberJs item) native;

  SVGNumberJs insertItemBefore(SVGNumberJs item, int index) native;

  SVGNumberJs removeItem(int index) native;

  SVGNumberJs replaceItem(SVGNumberJs item, int index) native;
}
