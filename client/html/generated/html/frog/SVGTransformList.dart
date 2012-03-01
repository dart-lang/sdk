
class _SVGTransformListImpl implements SVGTransformList native "*SVGTransformList" {

  final int numberOfItems;

  _SVGTransformImpl appendItem(_SVGTransformImpl item) native;

  void clear() native;

  _SVGTransformImpl consolidate() native;

  _SVGTransformImpl createSVGTransformFromMatrix(_SVGMatrixImpl matrix) native;

  _SVGTransformImpl getItem(int index) native;

  _SVGTransformImpl initialize(_SVGTransformImpl item) native;

  _SVGTransformImpl insertItemBefore(_SVGTransformImpl item, int index) native;

  _SVGTransformImpl removeItem(int index) native;

  _SVGTransformImpl replaceItem(_SVGTransformImpl item, int index) native;
}
