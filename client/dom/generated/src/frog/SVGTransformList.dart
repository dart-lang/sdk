
class SVGTransformList native "*SVGTransformList" {

  int numberOfItems;

  SVGTransform appendItem(SVGTransform item) native;

  void clear() native;

  SVGTransform consolidate() native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  SVGTransform getItem(int index) native;

  SVGTransform initialize(SVGTransform item) native;

  SVGTransform insertItemBefore(SVGTransform item, int index) native;

  SVGTransform removeItem(int index) native;

  SVGTransform replaceItem(SVGTransform item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
