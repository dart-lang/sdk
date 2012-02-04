
class _SVGTransformListJs extends _DOMTypeJs implements SVGTransformList native "*SVGTransformList" {

  final int numberOfItems;

  _SVGTransformJs appendItem(_SVGTransformJs item) native;

  void clear() native;

  _SVGTransformJs consolidate() native;

  _SVGTransformJs createSVGTransformFromMatrix(_SVGMatrixJs matrix) native;

  _SVGTransformJs getItem(int index) native;

  _SVGTransformJs initialize(_SVGTransformJs item) native;

  _SVGTransformJs insertItemBefore(_SVGTransformJs item, int index) native;

  _SVGTransformJs removeItem(int index) native;

  _SVGTransformJs replaceItem(_SVGTransformJs item, int index) native;
}
