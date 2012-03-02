
class _SVGPathSegListImpl implements SVGPathSegList native "*SVGPathSegList" {

  final int numberOfItems;

  _SVGPathSegImpl appendItem(_SVGPathSegImpl newItem) native;

  void clear() native;

  _SVGPathSegImpl getItem(int index) native;

  _SVGPathSegImpl initialize(_SVGPathSegImpl newItem) native;

  _SVGPathSegImpl insertItemBefore(_SVGPathSegImpl newItem, int index) native;

  _SVGPathSegImpl removeItem(int index) native;

  _SVGPathSegImpl replaceItem(_SVGPathSegImpl newItem, int index) native;
}
