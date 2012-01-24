
class SVGTransformListJS implements SVGTransformList native "*SVGTransformList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGTransformJS appendItem(SVGTransformJS item) native;

  void clear() native;

  SVGTransformJS consolidate() native;

  SVGTransformJS createSVGTransformFromMatrix(SVGMatrixJS matrix) native;

  SVGTransformJS getItem(int index) native;

  SVGTransformJS initialize(SVGTransformJS item) native;

  SVGTransformJS insertItemBefore(SVGTransformJS item, int index) native;

  SVGTransformJS removeItem(int index) native;

  SVGTransformJS replaceItem(SVGTransformJS item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
