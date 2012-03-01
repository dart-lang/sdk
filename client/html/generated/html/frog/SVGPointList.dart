
class _SVGPointListImpl implements SVGPointList native "*SVGPointList" {

  final int numberOfItems;

  _SVGPointImpl appendItem(_SVGPointImpl item) native;

  void clear() native;

  _SVGPointImpl getItem(int index) native;

  _SVGPointImpl initialize(_SVGPointImpl item) native;

  _SVGPointImpl insertItemBefore(_SVGPointImpl item, int index) native;

  _SVGPointImpl removeItem(int index) native;

  _SVGPointImpl replaceItem(_SVGPointImpl item, int index) native;
}
