
class _SVGNumberListImpl implements SVGNumberList native "*SVGNumberList" {

  final int numberOfItems;

  _SVGNumberImpl appendItem(_SVGNumberImpl item) native;

  void clear() native;

  _SVGNumberImpl getItem(int index) native;

  _SVGNumberImpl initialize(_SVGNumberImpl item) native;

  _SVGNumberImpl insertItemBefore(_SVGNumberImpl item, int index) native;

  _SVGNumberImpl removeItem(int index) native;

  _SVGNumberImpl replaceItem(_SVGNumberImpl item, int index) native;
}
