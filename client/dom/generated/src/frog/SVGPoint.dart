
class SVGPoint native "*SVGPoint" {

  num x;

  num y;

  SVGPoint matrixTransform(SVGMatrix matrix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
