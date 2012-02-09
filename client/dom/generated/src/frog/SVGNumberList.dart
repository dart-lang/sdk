
class _SVGNumberListJs extends _DOMTypeJs implements SVGNumberList native "*SVGNumberList" {

  final int numberOfItems;

  _SVGNumberJs appendItem(_SVGNumberJs item) native;

  void clear() native;

  _SVGNumberJs getItem(int index) native;

  _SVGNumberJs initialize(_SVGNumberJs item) native;

  _SVGNumberJs insertItemBefore(_SVGNumberJs item, int index) native;

  _SVGNumberJs removeItem(int index) native;

  _SVGNumberJs replaceItem(_SVGNumberJs item, int index) native;
}
