
class SVGTransformListJs extends DOMTypeJs implements SVGTransformList native "*SVGTransformList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGTransformJs appendItem(SVGTransformJs item) native;

  void clear() native;

  SVGTransformJs consolidate() native;

  SVGTransformJs createSVGTransformFromMatrix(SVGMatrixJs matrix) native;

  SVGTransformJs getItem(int index) native;

  SVGTransformJs initialize(SVGTransformJs item) native;

  SVGTransformJs insertItemBefore(SVGTransformJs item, int index) native;

  SVGTransformJs removeItem(int index) native;

  SVGTransformJs replaceItem(SVGTransformJs item, int index) native;
}
